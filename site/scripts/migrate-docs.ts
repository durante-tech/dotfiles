#!/usr/bin/env bun
/**
 * Migration script: converts docs/*.md -> site/src/content/docs/*.mdx
 * - Extracts title from first # heading
 * - Extracts description from first paragraph
 * - Adds Starlight frontmatter
 * - Rewrites internal links for Starlight routing
 * - Moves legacy terminals to legacy/ directory
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync, mkdtempSync, rmSync } from 'fs';
import { tmpdir } from 'os';
import { embedLessons } from './embed-lesson-components';
import { join, dirname, relative, basename, extname } from 'path';

const DOCS_DIR = join(import.meta.dir, '../../docs');
const TRACKED_DIR = join(import.meta.dir, '../src/content/docs');
const checking = process.argv.includes('--check');
const OUTPUT_DIR = checking ? mkdtempSync(join(tmpdir(), 'dotfiles-reference-')) : TRACKED_DIR;

// Disambiguation: when a bare filename matches multiple sources,
// prefer the neovim version (these come from getting-started pages that reference neovim docs)
const AMBIGUOUS_PREFER: Record<string, string> = {
	'daily-cheatsheet.md': 'neovim/daily-cheatsheet',
	'keybindings.md': 'neovim/keybindings',
	'troubleshooting.md': 'neovim/troubleshooting',
};

interface FileMapping {
	sourcePath: string; // relative to docs/
	outputSlug: string; // relative to content/docs/
}

function buildFileMappings(): FileMapping[] {
  return JSON.parse(readFileSync(join(import.meta.dir, 'reference-pages.json'), 'utf-8'));
}

function extractTitle(content: string): string {
	const match = content.match(/^#\s+(.+)$/m);
	return match ? match[1].trim() : 'Untitled';
}

function extractDescription(content: string): string {
	// Find first paragraph after the title (skip blank lines)
	const lines = content.split('\n');
	let foundTitle = false;
	let desc = '';

	for (const line of lines) {
		if (!foundTitle && line.startsWith('# ')) {
			foundTitle = true;
			continue;
		}
		if (foundTitle && line.trim() === '') continue;
		if (foundTitle && !line.startsWith('#') && !line.startsWith('|') && !line.startsWith('-') && !line.startsWith('*') && line.trim()) {
			desc = line.trim();
			break;
		}
		if (foundTitle && (line.startsWith('#') || line.startsWith('|'))) break;
	}

	if (!desc) return 'Dotfiles mastery course lesson.';

	// Clean markdown formatting
	desc = desc.replace(/\*\*(.+?)\*\*/g, '$1');
	desc = desc.replace(/\[(.+?)\]\(.+?\)/g, '$1');
	desc = desc.replace(/`(.+?)`/g, '$1');

	// Truncate to 160 chars
	if (desc.length > 160) {
		desc = desc.substring(0, 157) + '...';
	}

	return desc;
}

/**
 * Build a lookup from source-relative paths to output slugs
 * for link rewriting
 */
function buildLinkLookup(mappings: FileMapping[]): Map<string, string> {
	const lookup = new Map<string, string>();
	for (const m of mappings) {
		lookup.set(m.sourcePath, m.outputSlug);
	}
	return lookup;
}

/**
 * Rewrite internal markdown links to Starlight-compatible paths
 */
function rewriteLinks(content: string, sourceFile: string, lookup: Map<string, string>): string {
	const sourceDir = dirname(sourceFile);

	return content.replace(
		/\[([^\]]*)\]\(([^)]+)\)/g,
		(match, text, href) => {
			// Skip external links
			if (href.startsWith('http://') || href.startsWith('https://') || href.startsWith('#')) {
				return match;
			}

			// Split href into path and anchor
			const [pathPart, anchor] = href.split('#');

			if (!pathPart) {
				// Pure anchor link
				return match;
			}

			// Resolve relative path from source file's directory
			let resolvedPath: string;
			if (pathPart.startsWith('../') || pathPart.startsWith('./')) {
				// Resolve relative to source directory
				const parts = join(sourceDir, pathPart).split('/').filter(Boolean);
				// Normalize: remove any leading ../.. that goes above docs root
				resolvedPath = normalizePath(parts.join('/'));
			} else {
				resolvedPath = join(sourceDir, pathPart);
			}

			// Normalize the resolved path
			resolvedPath = resolvedPath.replace(/^\/+/, '');

			// Look up the output slug
			const outputSlug = lookup.get(resolvedPath);

			if (outputSlug) {
				const anchorPart = anchor ? `#${anchor}` : '';
				return `[${text}](/${outputSlug}/${anchorPart})`;
			}

			// If not found in lookup, try fuzzy matching by filename
			const targetFilename = basename(resolvedPath);

			// Check disambiguation table first
			if (AMBIGUOUS_PREFER[targetFilename]) {
				const anchorPart = anchor ? `#${anchor}` : '';
				return `[${text}](/${AMBIGUOUS_PREFER[targetFilename]}/${anchorPart})`;
			}

			const candidates: string[] = [];
			for (const [src, slug] of lookup.entries()) {
				if (basename(src) === targetFilename) {
					candidates.push(slug);
				}
				// Also try matching path suffix (e.g., workflows/editing.md)
				if (src.endsWith(resolvedPath)) {
					const anchorPart = anchor ? `#${anchor}` : '';
					return `[${text}](/${slug}/${anchorPart})`;
				}
			}

			if (candidates.length === 1) {
				const anchorPart = anchor ? `#${anchor}` : '';
				return `[${text}](/${candidates[0]}/${anchorPart})`;
			}

			// Skip warnings for non-.md links (code paths, etc.)
			if (resolvedPath.endsWith('.md')) {
				console.warn(`  Warning: Could not resolve link "${href}" from "${sourceFile}" (${candidates.length} candidates)`);
			}
			return match;
		}
	);
}

function normalizePath(p: string): string {
	const parts = p.split('/');
	const normalized: string[] = [];
	for (const part of parts) {
		if (part === '..') {
			normalized.pop();
		} else if (part !== '.' && part !== '') {
			normalized.push(part);
		}
	}
	return normalized.join('/');
}

function removeFirstHeading(content: string): string {
	// Remove the first # heading line (it becomes frontmatter title)
	return content.replace(/^#\s+.+\n+/, '');
}

/**
 * Escape JSX-problematic patterns in MDX content.
 * Only applies outside of code blocks (``` ... ```) and inline code (` ... `).
 */
function escapeForMdx(content: string): string {
	const lines = content.split('\n');
	let inCodeBlock = false;
	const result: string[] = [];

	for (const line of lines) {
		if (line.trim().startsWith('```')) {
			inCodeBlock = !inCodeBlock;
			result.push(line);
			continue;
		}

		if (inCodeBlock) {
			result.push(line);
			continue;
		}

		// Outside code blocks: escape < that aren't part of markdown links, HTML entities, or inline code
		let escaped = line;

		// Escape bare < followed by numbers or non-tag characters (like <10%, <=10)
		// Uses HTML entities so MDX doesn't parse as JSX
		escaped = escapeOutsideInlineCode(escaped);

		result.push(escaped);
	}

	return result.join('\n');
}

function escapeOutsideInlineCode(line: string): string {
	// Split by inline code spans and only process non-code parts
	const parts = line.split(/(`[^`]+`)/);
	return parts.map((part, i) => {
		// Odd indices are inline code spans
		if (i % 2 === 1) return part;
		// Even indices are regular text
		let escaped = part;
		// Escape bare < before numbers (JSX tag issue)
		escaped = escaped.replace(/<(?=\d|=\d)/g, '&lt;');
		// Escape bare {word} patterns (JSX expression issue)
		escaped = escaped.replace(/\{([a-zA-Z_][a-zA-Z0-9_]*)\}/g, '\\{$1\\}');
		return escaped;
	}).join('');
}

function migrate() {
	console.log('Starting migration...\n');

	const mappings = buildFileMappings();
	const lookup = buildLinkLookup(mappings);

	console.log(`Found ${mappings.length} files to migrate.\n`);

	// Clean output directory (except index.mdx which we'll create separately)
	// Don't delete the directory, just ensure it exists
	mkdirSync(OUTPUT_DIR, { recursive: true });

	let migrated = 0;
	let errors = 0;

	for (const mapping of mappings) {
		const sourceFullPath = join(DOCS_DIR, mapping.sourcePath);

		if (!existsSync(sourceFullPath)) {
			console.error(`  ERROR: Source not found: ${mapping.sourcePath}`);
			errors++;
			continue;
		}

		let content = readFileSync(sourceFullPath, 'utf-8');
		const title = extractTitle(content);
		const description = extractDescription(content);

		// Rewrite links
		content = rewriteLinks(content, mapping.sourcePath, lookup);

		// Escape JSX-problematic patterns for MDX
		content = escapeForMdx(content);

		// Remove first heading (becomes frontmatter title)
		content = removeFirstHeading(content);

		// Build frontmatter
		const frontmatter = [
			'---',
			`title: "${title.replace(/"/g, '\\"')}"`,
			`description: "${description.replace(/"/g, '\\"')}"`,
			'---',
			'',
		].join('\n');

		const existingPath = join(TRACKED_DIR, mapping.outputSlug + '.mdx');
		const metadata = existsSync(existingPath) ? readFileSync(existingPath, 'utf8').match(/^---\n[\s\S]*?\n---/)?.[0] : null;
		const outputContent = (metadata ?? frontmatter.trimEnd()) + '\n\n{/* reference:start */}\n\n' + content.trim() + '\n\n{/* reference:end */}\n';
		const outputPath = join(OUTPUT_DIR, mapping.outputSlug + '.mdx');

		// Ensure directory exists
		mkdirSync(dirname(outputPath), { recursive: true });
		writeFileSync(outputPath, outputContent, 'utf-8');

		console.log(`  Migrated: ${mapping.sourcePath} -> ${mapping.outputSlug}.mdx`);
		migrated++;
	}

	embedLessons(OUTPUT_DIR);
  if (checking) {
    for (const mapping of mappings) {
      const name = mapping.outputSlug + '.mdx';
      if (!existsSync(join(TRACKED_DIR, name)) || readFileSync(join(OUTPUT_DIR, name), 'utf8') !== readFileSync(join(TRACKED_DIR, name), 'utf8')) {
        console.error('Reference drift: ' + name); errors++;
      }
    }
  }
  if (errors) process.exitCode = 1;
  console.log(`References: ${migrated}; errors: ${errors}; check: ${checking}`);
}

try { migrate(); } finally { if (checking) rmSync(OUTPUT_DIR, {recursive: true, force: true}); }

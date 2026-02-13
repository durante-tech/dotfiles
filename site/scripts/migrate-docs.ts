#!/usr/bin/env bun
/**
 * Migration script: converts docs/*.md -> site/src/content/docs/*.mdx
 * - Extracts title from first # heading
 * - Extracts description from first paragraph
 * - Adds Starlight frontmatter
 * - Rewrites internal links for Starlight routing
 * - Moves legacy terminals to legacy/ directory
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync, statSync } from 'fs';
import { join, dirname, relative, basename, extname } from 'path';

const DOCS_DIR = join(import.meta.dir, '../../docs');
const OUTPUT_DIR = join(import.meta.dir, '../src/content/docs');

// Files that go to legacy/ directory
const LEGACY_FILES: Record<string, string> = {
	'alacritty/README.md': 'legacy/alacritty',
	'kitty/README.md': 'legacy/kitty',
	'wezterm/README.md': 'legacy/wezterm',
	'zed/README.md': 'legacy/zed',
};

// Files that map to root-level slugs (README.md files become index)
const README_MAPPINGS: Record<string, string> = {
	'README.md': 'docs-index',
	'course/README.md': 'course',
	'neovim/README.md': 'neovim',
	'tmux/README.md': 'tmux',
	'zsh/README.md': 'zsh',
	'ghostty/README.md': 'ghostty',
	'aerospace/README.md': 'aerospace',
	'karabiner/README.md': 'karabiner',
	'sketchybar/README.md': 'sketchybar',
	'starship/README.md': 'starship',
	'yazi/README.md': 'yazi',
	'atuin/README.md': 'atuin',
	'w3m/README.md': 'w3m',
	'mpd/README.md': 'mpd',
	'rmpc/README.md': 'rmpc',
	'scripts/README.md': 'scripts',
};

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

function getAllMdFiles(dir: string, base: string = ''): string[] {
	const files: string[] = [];
	for (const entry of readdirSync(dir)) {
		const fullPath = join(dir, entry);
		const relPath = base ? `${base}/${entry}` : entry;
		if (statSync(fullPath).isDirectory()) {
			files.push(...getAllMdFiles(fullPath, relPath));
		} else if (entry.endsWith('.md')) {
			files.push(relPath);
		}
	}
	return files;
}

function buildFileMappings(): FileMapping[] {
	const allFiles = getAllMdFiles(DOCS_DIR);
	const mappings: FileMapping[] = [];

	for (const file of allFiles) {
		let outputSlug: string;

		if (LEGACY_FILES[file]) {
			outputSlug = LEGACY_FILES[file];
		} else if (README_MAPPINGS[file]) {
			outputSlug = README_MAPPINGS[file];
		} else {
			// Regular files: remove .md extension
			outputSlug = file.replace(/\.md$/, '');
		}

		mappings.push({ sourcePath: file, outputSlug });
	}

	return mappings;
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

		const outputContent = frontmatter + content;
		const outputPath = join(OUTPUT_DIR, mapping.outputSlug + '.mdx');

		// Ensure directory exists
		mkdirSync(dirname(outputPath), { recursive: true });
		writeFileSync(outputPath, outputContent, 'utf-8');

		console.log(`  Migrated: ${mapping.sourcePath} -> ${mapping.outputSlug}.mdx`);
		migrated++;
	}

	// Create index page
	const indexContent = `---
title: "Dotfiles Mastery Course"
description: "A structured learning path from fresh macOS to keyboard-driven productivity. 8 levels, 39 lessons."
template: splash
hero:
  tagline: "From fresh macOS to keyboard-driven productivity in 7 weeks."
  actions:
    - text: Start the Course
      link: /course/
      icon: right-arrow
      variant: primary
    - text: Browse Documentation
      link: /docs-index/
      variant: minimal
---

import { Card, CardGrid } from '@astrojs/starlight/components';

## What You'll Learn

<CardGrid>
  <Card title="Level 0-1: Foundation" icon="rocket">
    Install everything, learn to open, edit, save, and quit files. Survive your first week.
  </Card>
  <Card title="Level 2-3: Navigation & Editing" icon="magnifier">
    Move fast with motions, text objects, and search. Edit surgically with operators.
  </Card>
  <Card title="Level 4-5: Intelligence & Windows" icon="puzzle">
    LSP code navigation, workspace management, and full keyboard-driven window control.
  </Card>
  <Card title="Level 6-7: Power & Mastery" icon="star">
    Master every tool in the system. Build custom workflows. Achieve keyboard fluency.
  </Card>
</CardGrid>

## The Stack

| Tool | Purpose | Theme |
|------|---------|-------|
| **Neovim** | Modal code editor | Rose-pine |
| **Tmux** | Terminal multiplexer | Catppuccin Mocha |
| **Zsh** | Shell + 100 aliases | Catppuccin Mocha |
| **AeroSpace** | Window manager | - |
| **Ghostty** | GPU terminal | Rose-pine |
| **Yazi** | File manager | Catppuccin |

> **Philosophy:** The keyboard is faster than the mouse. Every tool, every keybinding, every choice serves that goal.
`;

	writeFileSync(join(OUTPUT_DIR, 'index.mdx'), indexContent, 'utf-8');

	console.log(`\nMigration complete: ${migrated} files migrated, ${errors} errors.`);
}

migrate();

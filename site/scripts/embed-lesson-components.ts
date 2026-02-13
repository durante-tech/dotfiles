/**
 * Embeds CompleteLessonButton, LessonNav, LevelGateBanner, and mini-drills
 * into all lesson MDX files based on levels.json data.
 *
 * Run: bun scripts/embed-lesson-components.ts
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';

const SITE_DIR = join(import.meta.dir, '..');
const DOCS_DIR = join(SITE_DIR, 'src/content/docs');
const LEVELS_PATH = join(SITE_DIR, 'src/data/levels.json');

interface Lesson {
  id: string;
  slug: string;
  title: string;
  estimatedMinutes: number;
  type: string;
}

interface Level {
  level: number;
  title: string;
  lessons: Lesson[];
}

// Lessons that get mini-drills at the bottom
const MINI_DRILL_MAP: Record<string, { import: string; varName: string }> = {
  'getting-started/first-day': { import: 'neovim-core', varName: 'neovimCore' },
  'neovim/workflows/navigation': { import: 'neovim-navigation', varName: 'neovimNavigation' },
  'neovim/workflows/editing': { import: 'neovim-editing', varName: 'neovimEditing' },
  'neovim/workflows/search-replace': { import: 'neovim-core', varName: 'neovimCore' },
  'tmux/quick-start': { import: 'tmux-core', varName: 'tmuxCore' },
  'zsh/navigation-stack': { import: 'zsh-core', varName: 'zshCore' },
  'aerospace': { import: 'aerospace-core', varName: 'aerospaceCore' },
  'neovim/workflows/lsp': { import: 'neovim-navigation', varName: 'neovimNavigation' },
};

function getRelativePrefix(slug: string): string {
  const depth = slug.split('/').length - 1;
  return '../'.repeat(depth + 2);
}

function getDataRelativePrefix(slug: string): string {
  const depth = slug.split('/').length - 1;
  return '../'.repeat(depth + 2);
}

const levelsData: { levels: Level[] } = JSON.parse(readFileSync(LEVELS_PATH, 'utf-8'));

// Build flat ordered list of all lessons with level info
interface LessonEntry {
  id: string;
  slug: string;
  title: string;
  level: number;
  index: number; // global index
}

const allLessons: LessonEntry[] = [];
let globalIndex = 0;
for (const lvl of levelsData.levels) {
  for (const lesson of lvl.lessons) {
    allLessons.push({
      id: lesson.id,
      slug: lesson.slug,
      title: lesson.title,
      level: lvl.level,
      index: globalIndex++,
    });
  }
}

let modified = 0;
let skipped = 0;

for (const lesson of allLessons) {
  const mdxPath = join(DOCS_DIR, `${lesson.slug}.mdx`);

  if (!existsSync(mdxPath)) {
    console.warn(`  SKIP: ${mdxPath} not found`);
    skipped++;
    continue;
  }

  let content = readFileSync(mdxPath, 'utf-8');

  // Skip if already embedded
  if (content.includes('CompleteLessonButton')) {
    console.log(`  SKIP: ${lesson.slug} (already embedded)`);
    skipped++;
    continue;
  }

  const prefix = getRelativePrefix(lesson.slug);
  const dataPrefix = getDataRelativePrefix(lesson.slug);

  // Compute prev/next
  const prev = lesson.index > 0 ? allLessons[lesson.index - 1] : null;
  const next = lesson.index < allLessons.length - 1 ? allLessons[lesson.index + 1] : null;

  // Build imports
  const imports: string[] = [
    `import CompleteLessonButton from '${prefix}components/CompleteLessonButton.tsx';`,
  ];

  if (lesson.level > 0) {
    imports.push(
      `import LevelGateBanner from '${prefix}components/LevelGateBanner.tsx';`
    );
  }

  // Mini-drill imports
  const drill = MINI_DRILL_MAP[lesson.slug];
  if (drill) {
    imports.push(
      `import KeybindingTrainer from '${prefix}components/KeybindingTrainer.tsx';`,
      `import ${drill.varName} from '${dataPrefix}data/keybindings/${drill.import}.json';`
    );
  }

  // Build footer components
  const footerParts: string[] = [];

  if (drill) {
    footerParts.push('');
    footerParts.push('---');
    footerParts.push('');
    footerParts.push('## Practice');
    footerParts.push('');
    footerParts.push(`<KeybindingTrainer client:idle drillSet={${drill.varName}} maxQuestions={5} />`);
  }

  footerParts.push('');

  // CompleteLessonButton props
  let btnProps = `lessonId="${lesson.id}" slug="${lesson.slug}"`;
  if (next) {
    btnProps += ` nextLessonSlug="${next.slug}" nextLessonTitle="${next.title}"`;
  }
  footerParts.push(`<CompleteLessonButton client:idle ${btnProps} />`);

  // Insert imports after frontmatter
  const frontmatterEnd = content.indexOf('---', content.indexOf('---') + 3);
  if (frontmatterEnd === -1) {
    console.warn(`  SKIP: ${lesson.slug} (no frontmatter found)`);
    skipped++;
    continue;
  }

  const insertPoint = frontmatterEnd + 3;
  const beforeImports = content.slice(0, insertPoint);
  const afterImports = content.slice(insertPoint);

  // Build the gate banner line
  const gateBanner = lesson.level > 0
    ? `\n<LevelGateBanner level={${lesson.level}} client:load />\n`
    : '';

  content = beforeImports + '\n\n' + imports.join('\n') + '\n' + gateBanner + afterImports;

  // Append footer
  content = content.trimEnd() + '\n' + footerParts.join('\n') + '\n';

  writeFileSync(mdxPath, content, 'utf-8');
  console.log(`  OK: ${lesson.slug} (L${lesson.level}, #${lesson.id})`);
  modified++;
}

console.log(`\nDone! Modified: ${modified}, Skipped: ${skipped}`);

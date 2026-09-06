/** Deterministic course wrappers around Markdown-generated reference bodies. */
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';
import levels from '../src/data/levels.json';

const miniDrills: Record<string, string> = {
  'getting-started/first-day': 'neovim-core',
  'neovim/workflows/navigation': 'neovim-navigation',
  'neovim/workflows/editing': 'neovim-editing',
  'neovim/workflows/search-replace': 'neovim-core',
  'tmux/quick-start': 'tmux-core', 'zsh/navigation-stack': 'zsh-core',
  aerospace: 'aerospace-core', 'neovim/workflows/lsp': 'neovim-navigation',
};

export function embedLessons(directory: string): void {
  const lessons = levels.levels.flatMap(level => level.lessons.map(lesson => ({...lesson, level: level.level})));
  const slugs = [...lessons.map(lesson => lesson.slug), 'course'];
  for (const slug of slugs) {
    const path = join(directory, slug + '.mdx');
    if (!existsSync(path)) throw new Error('Missing lesson reference: ' + slug);
    const source = readFileSync(path, 'utf8');
    const metadata = source.match(/^---\n[\s\S]*?\n---/)?.[0];
    const body = source.match(/\{\/\* reference:start \*\/\}([\s\S]*?)\{\/\* reference:end \*\/\}/)?.[1].trim();
    if (!metadata || body === undefined) throw new Error('Run migrate-docs.ts before embedding: ' + slug);
    const prefix = '../'.repeat(slug.split('/').length + 1);
    const imports: string[] = [], header: string[] = [], footer: string[] = [];
    if (slug === 'course') {
      imports.push(`import LevelMap from '${prefix}components/LevelMap.tsx';`);
      header.push('<LevelMap client:idle />');
    } else {
      const index = lessons.findIndex(lesson => lesson.slug === slug), lesson = lessons[index], next = lessons[index + 1];
      imports.push(`import CompleteLessonButton from '${prefix}components/CompleteLessonButton.tsx';`);
      if (lesson.level > 0) {
        imports.push(`import LevelGateBanner from '${prefix}components/LevelGateBanner.tsx';`);
        header.push(`<LevelGateBanner level={${lesson.level}} client:load />`);
      }
      if (miniDrills[slug]) {
        imports.push(`import KeybindingTrainer from '${prefix}components/KeybindingTrainer.tsx';`, `import drills from '${prefix}data/keybindings/${miniDrills[slug]}.json';`);
        footer.push('---\n\n## Practice\n\n<KeybindingTrainer client:idle drillSet={drills} maxQuestions={5} />');
      }
      const nextProps = next ? ` nextLessonSlug=${JSON.stringify(next.slug)} nextLessonTitle=${JSON.stringify(next.title)}` : '';
      footer.push(`<CompleteLessonButton client:idle lessonId=${JSON.stringify(lesson.id)} slug=${JSON.stringify(slug)}${nextProps} />`);
    }
    writeFileSync(path, [metadata, imports.join('\n'), ...header, '{/* reference:start */}', body, '{/* reference:end */}', ...footer].join('\n\n') + '\n');
  }
}

if (import.meta.main) embedLessons(join(import.meta.dir, '../src/content/docs'));

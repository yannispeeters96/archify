#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..');
const sourceRoot = path.join(repoRoot, 'archify');
const targetRoot = process.argv[2] ? path.resolve(process.argv[2]) : null;

if (!targetRoot) {
  console.error('usage: node scripts/stage-package.mjs <output-dir>');
  process.exit(1);
}

if (!fs.existsSync(path.join(sourceRoot, 'renderers', 'shared', 'generated-validators.mjs'))) {
  console.error('generated validators are missing — run npm run generate:validators in archify/');
  process.exit(1);
}

function shouldCopy(sourcePath) {
  const relative = path.relative(sourceRoot, sourcePath);
  if (!relative) return true;
  const normalized = relative.split(path.sep).join('/');
  const segments = normalized.split('/');

  if (normalized === 'node_modules' || normalized.startsWith('node_modules/')) return false;
  if (normalized === 'test' || normalized.startsWith('test/')) return false;
  if (normalized === 'scripts/generate-validators.mjs') return false;
  if (segments.includes('.hive') || segments.includes('.workbuddy')) return false;
  if (segments.some((segment) => segment.startsWith('.validator-check-'))) return false;
  if (segments[segments.length - 1] === '.DS_Store') return false;
  return true;
}

fs.rmSync(targetRoot, { recursive: true, force: true });
fs.mkdirSync(path.dirname(targetRoot), { recursive: true });
fs.cpSync(sourceRoot, targetRoot, {
  recursive: true,
  filter: shouldCopy,
});

const packageJsonPath = path.join(targetRoot, 'package.json');
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
for (const field of [
  'scripts',
  'dependencies',
  'devDependencies',
  'optionalDependencies',
  'peerDependencies',
  'bundledDependencies',
  'bundleDependencies',
]) {
  delete packageJson[field];
}
fs.writeFileSync(packageJsonPath, `${JSON.stringify(packageJson, null, 2)}\n`);
fs.rmSync(path.join(targetRoot, 'package-lock.json'), { force: true });

process.stdout.write(`staged ${targetRoot}\n`);

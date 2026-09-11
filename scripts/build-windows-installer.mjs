#!/usr/bin/env node

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, '..');
const packageJson = JSON.parse(fs.readFileSync(path.join(repoRoot, 'archify', 'package.json'), 'utf8'));
const version = packageJson.version;
const outputFile = path.resolve(process.argv[2] || path.join(repoRoot, `archify-windows-installer-v${version}.exe`));
const providedStageDir = process.argv[3] ? path.resolve(process.argv[3]) : null;
const stageScript = path.join(repoRoot, 'scripts', 'stage-package.mjs');
const nsisScript = path.join(repoRoot, 'installer', 'archify-windows.nsi');
let cleanupRoot = null;
let stageDir = providedStageDir;
const nsisPath = (value) => value.replace(/\\/g, '/');

if (!stageDir) {
  cleanupRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'archify-windows-installer-'));
  stageDir = path.join(cleanupRoot, 'archify');
  const stageResult = spawnSync(process.execPath, [stageScript, stageDir], {
    cwd: repoRoot,
    encoding: 'utf8',
  });
  if (stageResult.status !== 0) {
    process.stderr.write(stageResult.stdout || '');
    process.stderr.write(stageResult.stderr || '');
    process.exit(stageResult.status ?? 1);
  }
}

fs.mkdirSync(path.dirname(outputFile), { recursive: true });
const nsisResult = spawnSync('makensis', [
  `-DARCHIFY_STAGE_DIR=${nsisPath(stageDir)}`,
  `-DARCHIFY_OUTPUT_FILE=${nsisPath(outputFile)}`,
  `-DARCHIFY_VERSION=${version}`,
  nsisScript,
], {
  cwd: repoRoot,
  encoding: 'utf8',
});

if (cleanupRoot) fs.rmSync(cleanupRoot, { recursive: true, force: true });
if (nsisResult.error) {
  process.stderr.write(`${nsisResult.error.message}\n`);
  process.exit(1);
}
if (nsisResult.status !== 0) {
  process.stderr.write(nsisResult.stdout || '');
  process.stderr.write(nsisResult.stderr || '');
  process.exit(nsisResult.status ?? 1);
}

process.stdout.write(nsisResult.stdout || '');
process.stdout.write(`built ${outputFile}\n`);

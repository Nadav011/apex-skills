#!/usr/bin/env node
/**
 * apex-skills CLI
 * Usage: npx apex-skills [install] [--platform claude-code|gemini|kiro|cursor|codex]
 */

import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const VERSION = '2.0.0';

function detectPlatform() {
  const platform = process.argv.find(a => a.startsWith('--platform='))?.split('=')[1]
    || process.argv[process.argv.indexOf('--platform') + 1];
  if (platform) return platform;
  if (fs.existsSync(path.join(os.homedir(), '.claude'))) return 'claude-code';
  if (fs.existsSync(path.join(os.homedir(), '.gemini'))) return 'gemini';
  if (fs.existsSync(path.join(os.homedir(), '.kiro'))) return 'kiro';
  if (fs.existsSync(path.join(os.homedir(), '.codex'))) return 'codex';
  return 'claude-code';
}

function targetDir(platform) {
  const home = os.homedir();
  const dirs = {
    'claude-code': path.join(home, '.claude', 'skills'),
    'gemini': path.join(home, '.gemini', 'skills'),
    'kiro': path.join(home, '.kiro', 'agents'),
    'codex': path.join(home, '.codex', 'skills'),
    'cursor': path.join(process.cwd(), '.cursor', 'rules'),
  };
  return dirs[platform] || dirs['claude-code'];
}

function installFromLocal(skillsDir, dest) {
  let installed = 0, updated = 0;
  const skills = fs.readdirSync(skillsDir, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => d.name);

  for (const name of skills) {
    const src = path.join(skillsDir, name, 'SKILL.md');
    if (!fs.existsSync(src)) continue;
    const destDir = path.join(dest, name);
    const destFile = path.join(destDir, 'SKILL.md');
    fs.mkdirSync(destDir, { recursive: true });
    const srcContent = fs.readFileSync(src, 'utf8');
    if (fs.existsSync(destFile) && fs.readFileSync(destFile, 'utf8') === srcContent) continue;
    const isUpdate = fs.existsSync(destFile);
    fs.writeFileSync(destFile, srcContent);
    isUpdate ? updated++ : installed++;
    console.log(`  ${isUpdate ? '↑' : '+'} ${name.padEnd(28)} ${isUpdate ? '(updated)' : ''}`);
  }
  return { installed, updated };
}

const command = process.argv[2] || 'install';

if (command === '--version' || command === '-v') {
  console.log(`apex-skills v${VERSION}`);
  process.exit(0);
}

if (command === 'list') {
  const skillsDir = path.join(__dirname, '..', 'skills');
  const skills = fs.readdirSync(skillsDir, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => d.name);
  console.log(`\nAPEX Skills (${skills.length}):\n`);
  skills.forEach(s => console.log(`  - ${s}`));
  process.exit(0);
}

if (command === 'install' || !command.startsWith('-')) {
  const platform = detectPlatform();
  const dest = targetDir(platform);

  console.log('\n╔══════════════════════════════════════════╗');
  console.log('║       APEX Skills Installer v2.0         ║');
  console.log('╚══════════════════════════════════════════╝\n');
  console.log(`Platform : ${platform}`);
  console.log(`Target   : ${dest}\n`);

  fs.mkdirSync(dest, { recursive: true });

  const localSkills = path.join(__dirname, '..', 'skills');
  const { installed, updated } = installFromLocal(localSkills, dest);

  console.log(`\n✅ Done — ${installed} new, ${updated} updated (${installed + updated} total skills)\n`);
  console.log('Restart Claude Code / your AI assistant to activate.\n');
}

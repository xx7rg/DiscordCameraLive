// Caminho do standalone dentro do pacote (dev: repo; AppImage: extraResources)
import { app } from 'electron';
import path from 'path';
import { spawn } from 'child_process';
import fs from 'fs';

export function findStandaloneScript(): string {
  // 1. pasta dev: ../standalone/discordcameralive-standalone.sh (relativo a dist-electron)
  const dev = path.join(app.getAppPath(), '..', 'standalone', 'discordcameralive-standalone.sh');
  if (fs.existsSync(dev)) return dev;

  // 2. AppImage: extraResources copia para resources/extra/standalone/
  const bundled = path.join(process.resourcesPath, 'extra', 'standalone', 'discordcameralive-standalone.sh');
  if (fs.existsSync(bundled)) return bundled;

  // 3. fallback: ao lado do binário
  const beside = path.join(path.dirname(process.execPath), 'standalone', 'discordcameralive-standalone.sh');
  if (fs.existsSync(beside)) return beside;

  throw new Error('Nao encontrei discordcameralive-standalone.sh');
}

export interface ScriptResult {
  code: number | null;
  stdout: string;
  stderr: string;
}

// Roda o script e resolve com a saida completa (para acoes que terminam rapido: status).
export function runScript(args: string[], onChunk?: (chunk: string) => void): Promise<ScriptResult> {
  return new Promise((resolve, reject) => {
    let stdout = '', stderr = '';
    let child;
    try {
      child = spawn('sh', [findStandaloneScript(), ...args], {
        env: { ...process.env },
        // A reversao do bypass roda em background depois do app.quit(); sem detached o filho
        // morreria junto com o processo pai e o Discord ficaria com a injecao pendurada.
        detached: true,
      });
      child.unref();
    } catch (err) {
      reject(err);
      return;
    }

    child.stdout.on('data', (d: Buffer) => {
      const s = d.toString();
      stdout += s;
      onChunk?.(s);
    });
    child.stderr.on('data', (d: Buffer) => {
      const s = d.toString();
      stderr += s;
      onChunk?.(s);
    });
    child.on('error', reject);
    child.on('close', (code) => resolve({ code, stdout, stderr }));
  });
}

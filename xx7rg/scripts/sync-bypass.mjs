// Gera electron/bypass.ts a partir do standalone de verdade.
//
// A GUI carrega o bypass como uma string embutida, porque o electron-builder empacota o app
// num asar e um arquivo solto nao sobreviveria. Isso cria uma copia, e copia feita a mao
// diverge sem ninguem perceber: a GUI compila igual, roda igual, e injeta o bypass velho.
//
// Rodar sem argumento regrava o arquivo. Com --check ele nao escreve nada e sai com codigo 1
// se estiver desatualizado, que e o que serve para barrar no CI.

import { readFileSync, writeFileSync, existsSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const AQUI = dirname(fileURLToPath(import.meta.url));
const ORIGEM = join(AQUI, "..", "..", "standalone", "discordcameralive.js");
const DESTINO = join(AQUI, "..", "electron", "bypass.ts");

if (!existsSync(ORIGEM)) {
    console.error(`[sync-bypass] nao achei o standalone em ${ORIGEM}`);
    process.exit(1);
}

const origem = readFileSync(ORIGEM, "utf8");
const gerado = `export const bypassCode = ${JSON.stringify(origem)}`;
const atual = existsSync(DESTINO) ? readFileSync(DESTINO, "utf8") : "";

if (atual === gerado) {
    console.log(`[sync-bypass] em dia (${origem.length} bytes)`);
    process.exit(0);
}

if (process.argv.includes("--check")) {
    console.error("[sync-bypass] electron/bypass.ts esta desatualizado em relacao ao standalone.");
    console.error("[sync-bypass] rode: npm run sync-bypass");
    process.exit(1);
}

writeFileSync(DESTINO, gerado);
console.log(`[sync-bypass] atualizado a partir do standalone (${origem.length} bytes)`);

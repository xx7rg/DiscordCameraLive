import './style.css'

declare global {
  interface Window {
    api: {
      platform: string;
      activate: (proxy?: string) => Promise<void>;
      deactivate: () => Promise<void>;
      getStatus: () => Promise<string>;
      getPlatform: () => Promise<string>;
      getStartup: () => Promise<boolean>;
      setStartup: (enabled: boolean) => Promise<void>;
      onRefreshStartup: (callback: () => void) => void;
      onRefreshStatus: (callback: () => void) => void;
      resizeWindow: (height: number) => void;
      setTheme: (theme: string) => void;
    }
  }
}

const platform = window.api.platform;
const isMac = platform === 'darwin';
const isLinux = platform === 'linux';
const reloadShortcut = isMac ? 'Cmd + R' : 'Ctrl + R';

function applyPlatformCopy() {
  document.body.classList.toggle('darwin', isMac);

  const startupLabel = document.getElementById('startupLabel');
  if (startupLabel) {
    // Linux: autostart XDG; Windows/Mac: login item. O rotulo acompanha o SO.
    startupLabel.textContent = isMac ? 'Iniciar com o Mac' : isLinux ? 'Iniciar com o sistema' : 'Iniciar com o Windows';
  }

  const closeHint = document.getElementById('closeHint');
  if (closeHint) {
    closeHint.textContent = isMac
      ? 'Fechar a janela esconde o app na barra de menus, junto do relógio — para reverter tudo, saia pelo ícone de lá.'
      : 'Fechar a janela esconde o app na bandeja, junto do relógio — para reverter tudo, saia pelo ícone de lá.';
  }

  const reloadKeys = document.getElementById('reloadKeys');
  if (reloadKeys) reloadKeys.textContent = reloadShortcut;
}

// ---------------------------------------------------------------------------
// Tema claro/escuro — persistido em localStorage e avisado ao main process
// (o titleBarOverlay do Windows precisa saber a cor de fundo da janela).
// ---------------------------------------------------------------------------
const THEME_KEY = 'discordcameralive-theme';

function applyTheme(theme: 'light' | 'dark') {
  document.documentElement.dataset.theme = theme;
  try {
    localStorage.setItem(THEME_KEY, theme);
  } catch {
    // localStorage pode falhar (perfil sem escrita); o tema ainda vale na sessao.
  }
  window.api.setTheme(theme);
}

function initTheme() {
  // Tema padrao: dark. So usa o claro se estiver salvo explicitamente.
  let theme: 'light' | 'dark' = 'dark';
  try {
    const saved = localStorage.getItem(THEME_KEY);
    if (saved === 'dark' || saved === 'light') theme = saved;
  } catch {
    // cai no default escuro
  }
  applyTheme(theme);
}

const statusIndicator = document.getElementById('statusIndicator')!;
const statusText = document.getElementById('statusText')!;
const statusTag = document.getElementById('statusTag')!;
const statusCard = document.getElementById('statusCard')!;
const toggleBtn = document.getElementById('toggleBtn') as HTMLButtonElement;
const btnText = document.getElementById('btnText')!;
const warningAlert = document.getElementById('warningAlert')!;
const warnBtn = document.getElementById('warnBtn') as HTMLButtonElement;
const proxyInput = document.getElementById('proxyInput') as HTMLInputElement;
const startupToggle = document.getElementById('startupToggle') as HTMLInputElement;
const themeBtn = document.getElementById('themeBtn') as HTMLButtonElement;

let currentState = 'INACTIVE';

// ---------------------------------------------------------------------------
// Popover do aviso: abre/fecha no clique do botao "!", e fecha ao clicar fora.
// ---------------------------------------------------------------------------
function setWarningOpen(open: boolean) {
  warningAlert.classList.toggle('open', open);
  warnBtn.setAttribute('aria-expanded', String(open));
  // O popover flutua sobre o conteudo, entao a altura da janela nao muda.
  fitWindowToContent();
}

warnBtn.addEventListener('click', (event) => {
  event.stopPropagation();
  setWarningOpen(!warningAlert.classList.contains('open'));
});

document.addEventListener('click', (event) => {
  const target = event.target as Node;
  if (!warningAlert.contains(target) && target !== warnBtn) {
    setWarningOpen(false);
  }
});

// ---------------------------------------------------------------------------
// Tema: botao alterna; inicia com o valor salvo.
// ---------------------------------------------------------------------------
themeBtn.addEventListener('click', () => {
  const next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
  applyTheme(next);
});

// ---------------------------------------------------------------------------

// O warning do bypass ativo faz o conteudo crescer; a janela e fixa, entao reportamos a altura
// necessaria para o main process redimensionar e nada ficar cortado.
function fitWindowToContent() {
  const container = document.querySelector('.container');
  if (!container) return;
  // +1 px de folga: sem isto a ultima linha as vezes ficava cortada por causa do arredondamento.
  const height = Math.ceil(container.getBoundingClientRect().height + 1);
  window.api.resizeWindow(height);
}

async function updateStatus() {
  try {
    const status = await window.api.getStatus();
    currentState = status;
    
    statusIndicator.className = 'status-indicator';
    statusTag.className = 'status-tag';
    toggleBtn.disabled = false;
    toggleBtn.classList.remove('loading', 'deactivate', 'overwrite');

    if (status === 'ACTIVE') {
      statusText.innerText = 'DiscordCameraLive está Ativo';
      statusTag.textContent = 'Ativo';
      statusTag.classList.add('tag--ok');
      btnText.innerText = 'Desativar Bypass';
      toggleBtn.classList.add('deactivate');
      statusCard.hidden = true;
    } else if (status === 'OTHER_MOD') {
      statusText.innerText = 'Outro mod detectado';
      statusTag.textContent = 'Conflito';
      statusTag.classList.add('tag--warn');
      btnText.innerText = 'Sobrescrever e Ativar';
      toggleBtn.classList.add('overwrite');
      statusCard.hidden = false;
    } else if (status === 'NOT_FOUND') {
      statusText.innerText = 'Discord não encontrado';
      statusTag.textContent = 'Ausente';
      statusTag.classList.add('tag--danger');
      toggleBtn.disabled = true;
      btnText.innerText = 'Não Disponível';
      statusCard.hidden = false;
    } else {
      statusText.innerText = 'Discord limpo. Pronto para injetar.';
      statusTag.textContent = 'Pronto';
      statusTag.classList.add('tag--ok');
      btnText.innerText = 'Ativar Bypass';
      statusCard.hidden = true;
    }
  } catch (err) {
    console.error(err);
    statusText.innerText = 'Erro ao buscar status';
    statusTag.textContent = 'Erro';
    statusTag.classList.add('tag--danger');
    statusCard.hidden = false;
  }
  // Depois de mudar o estado, ajusta a janela ao novo tamanho do conteudo.
  fitWindowToContent();
}

toggleBtn.addEventListener('click', async () => {
  toggleBtn.disabled = true;
  toggleBtn.classList.add('loading');

  try {
    if (currentState === 'ACTIVE') {
      await window.api.deactivate();
    } else {
      const proxy = proxyInput.value.trim();
      await window.api.activate(proxy);

      // Popup de aviso
      setWarningOpen(true);
    }
  } catch (err) {
    alert('Erro: ' + err);
  }

  await updateStatus();
});

// Inicialização
applyPlatformCopy();
initTheme();
updateStatus();
refreshStartup();
fitWindowToContent();

async function refreshStartup() {
  try {
    startupToggle.checked = await window.api.getStartup();
  } catch (err) {
    console.error(err);
  }
}

startupToggle.addEventListener('change', async () => {
  await window.api.setStartup(startupToggle.checked);
});

// A bandeja tambem tem esses controles; sem os avisos, os dois ficariam dessincronizados.
window.api.onRefreshStartup(refreshStartup);
window.api.onRefreshStatus(updateStatus);

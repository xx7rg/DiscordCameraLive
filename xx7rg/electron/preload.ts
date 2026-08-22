import { contextBridge, ipcRenderer } from 'electron';

// contextIsolation:true mantém este mundo separado do renderer; so o que e
// exposto aqui via contextBridge fica visivel como window.api la fora. O
// renderer nunca ganha require/process/fs, so os metodos abaixo.
contextBridge.exposeInMainWorld('api', {
  platform: process.platform,
  activate: (proxy?: string) => ipcRenderer.invoke('activate', proxy),
  deactivate: () => ipcRenderer.invoke('deactivate'),
  getStatus: () => ipcRenderer.invoke('get-status'),
  getPlatform: () => ipcRenderer.invoke('get-platform'),
  getStartup: () => ipcRenderer.invoke('get-startup'),
  setStartup: (enabled: boolean) => ipcRenderer.invoke('set-startup', enabled),
  onRefreshStartup: (callback: () => void) => ipcRenderer.on('refresh-startup', callback),
  onRefreshStatus: (callback: () => void) => ipcRenderer.on('refresh-status', callback),
  resizeWindow: (height: number) => ipcRenderer.send('resize-window', height),
  setTheme: (theme: string) => ipcRenderer.send('set-theme', theme),
});

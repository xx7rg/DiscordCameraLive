// Aplica o tema antes do CSS carregar para nao piscar claro.
// Padrao: dark; respeita o que o usuario salvou.
try {
  var t = localStorage.getItem('discordcameralive-theme');
  document.documentElement.dataset.theme = t === 'light' ? 'light' : 'dark';
} catch (e) {
  document.documentElement.dataset.theme = 'dark';
}

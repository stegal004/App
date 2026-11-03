const modal = document.getElementById('study-modal');
const openStudy = document.getElementById('start-study');
const closeStudy = document.querySelector('.close-modal');

function setModal(isOpen) {
  modal.classList.toggle('open', isOpen);
  modal.setAttribute('aria-hidden', String(!isOpen));
  if (isOpen) document.querySelector('.modal-options button').focus();
}

openStudy.addEventListener('click', () => setModal(true));
closeStudy.addEventListener('click', () => setModal(false));
modal.addEventListener('click', (event) => { if (event.target === modal) setModal(false); });
document.addEventListener('keydown', (event) => { if (event.key === 'Escape') setModal(false); });
document.querySelectorAll('.modal-options button, .play').forEach((button) => {
  button.addEventListener('click', () => setModal(false));
});

const appearanceToggle = document.getElementById('appearance-toggle');
const appearanceMenu = document.getElementById('appearance-menu');
const themeOptions = document.querySelectorAll('.theme-option');
const savedTheme = localStorage.getItem('studio-theme') || 'light';

function setTheme(theme) {
  document.body.dataset.theme = theme;
  localStorage.setItem('studio-theme', theme);
  themeOptions.forEach((option) => option.classList.toggle('selected', option.dataset.theme === theme));
}

setTheme(savedTheme);
appearanceToggle.addEventListener('click', () => {
  const isOpen = !appearanceMenu.hidden;
  appearanceMenu.hidden = isOpen;
  appearanceToggle.setAttribute('aria-expanded', String(!isOpen));
});
themeOptions.forEach((option) => option.addEventListener('click', () => {
  setTheme(option.dataset.theme);
  appearanceMenu.hidden = true;
  appearanceToggle.setAttribute('aria-expanded', 'false');
}));
document.addEventListener('click', (event) => {
  if (!event.target.closest('.theme-control')) {
    appearanceMenu.hidden = true;
    appearanceToggle.setAttribute('aria-expanded', 'false');
  }
});

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => navigator.serviceWorker.register('/service-worker.js'));
}

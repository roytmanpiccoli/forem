import { h, render } from 'preact';
import { ArticleForm } from '../article-form/articleForm';
import { Snackbar } from '../Snackbar';
import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function loadForm() {
  // The Snackbar for the article page
  const snackZone = document.getElementById('snack-zone');

  if (snackZone) {
    render(<Snackbar lifespan={3} />, snackZone);
  }

  getUserDataAndCsrfToken().then(({ currentUser, csrfToken }) => {
    window.currentUser = currentUser;
    window.csrfToken = csrfToken;

    const root = document.querySelector('main');
    const { article, organizations, version, siteLogo } = root.dataset;

    render(
      <ArticleForm
        article={article}
        organizations={organizations}
        version={version}
        siteLogo={siteLogo}
      />,
      root,
      root.firstElementChild,
    );
  });
}

document.ready.then(() => {
  loadForm();
  window.InstantClick.on('change', () => {
    if (document.getElementById('article-form')) {
      loadForm();
    }
  });
});

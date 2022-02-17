import { h } from 'preact';
import { JSDOM } from 'jsdom';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Preview } from '../Preview';

const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
global.window = doc.defaultView;
global.window.currentUser = Object.freeze({
  id: 1,
  name: 'Guy Fieri',
  username: 'guyfieri',
  profile_image_90:
    '/uploads/user/profile_image/41/0841dbe2-208c-4daa-b498-b2f01f3d37b2.png',
});

let errors;

function getPreviewResponse() {
  return {
    processed_html:
      '<p>My Awesome Post! Not very long, but still very awesome.</p>↵↵',
    title: 'My Awesome Post',
    tags: null,
    cover_image: 'http://lorempixel.com/400/200/',
  };
}

function getArticleState() {
  return {
    id: null,
    title: 'My Awesome Post',
    tagList: 'javascript, career, ',
    description: 'Some description',
    canonicalUrl: '',
    series: '',
    allSeries: ['Learn Something new a day'],
    bodyMarkdown:
      '---↵title: My Awesome Post↵published: false↵description: ↵tags: ↵---↵↵My Awesome Post Not very long, but still very awesome! ↵',
    submitting: false,
    editing: false,
    mainImage: '/i/9ca8kb1cu34mobypm5yx.png',
    organizations: [
      {
        id: 4,
        bg_color_hex: '',
        name: 'DEV',
        text_color_hex: '',
        profile_image_90:
          '/uploads/organization/profile_image/4/1689e7ae-6306-43cd-acba-8bde7ed80a17.JPG',
      },
    ],
    organizationId: null,
    errors: null,
    edited: true,
    updatedAt: null,
    version: 'v2',
    helpFor: null,
    helpPosition: null,
  };
}

describe('<Preview />', () => {
  beforeEach(() => {
    errors = null;
  });

  it('should have no a11y violations', async () => {
    const { container } = render(
      <Preview
        previewResponse={getPreviewResponse()}
        articleState={getArticleState()}
        errors={errors}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('shows the correct title', () => {
    const previewResponse = getPreviewResponse();
    const { queryByText } = render(
      <Preview
        previewResponse={previewResponse}
        articleState={getArticleState()}
        errors={errors}
      />,
    );

    expect(queryByText(previewResponse.title)).toBeDefined();
  });

  it('shows the correct tags', () => {
    const { queryByText } = render(
      <Preview
        previewResponse={getPreviewResponse()}
        articleState={getArticleState()}
        errors={errors}
      />,
    );

    expect(queryByText(`javascript`)).toBeDefined();
    expect(queryByText(`career`)).toBeDefined();
  });

  it('shows a cover image in the preview if one exists', () => {
    const articleState = { ...getArticleState(), previewShowing: true };
    const { getByTestId, getByAltText } = render(
      <Preview
        previewResponse={getPreviewResponse()}
        articleState={articleState}
        errors={errors}
      />,
    );
    const coverImage = getByAltText(/post preview cover/i);

    getByTestId('article-form__cover');

    expect(coverImage.src).toEqual('http://lorempixel.com/400/200/');
  });

  it('does not show a cover image in the preview if one does not exist', () => {
    const articleState = { ...getArticleState(), mainImage: null };
    const previewResponse = { ...getPreviewResponse(), cover_image: null };
    const { queryByTestId } = render(
      <Preview
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );

    expect(queryByTestId('article-form__cover')).toBeNull();
  });

  // TODO: need to write a test for the cover image for v1
});

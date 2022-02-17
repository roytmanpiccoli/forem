import { BREAKPOINTS } from '../../../../app/javascript/shared/components/useMediaQuery';

describe('Reading List Archive', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV1User.json').as('user');
    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/');
    });
  });

  it('should load an empty reading list', () => {
    cy.intercept(
      Cypress.config().baseUrl +
        'search/reactions?page=0&per_page=80&status%5B%5D=valid&status%5B%5D=confirmed',
      { fixture: 'search/emptyReadingList.json' },
    ).as('emptyReadingList');

    cy.visit('/readinglist');
    cy.wait('@emptyReadingList');

    cy.findByRole('main')
      .as('main')
      .findByText(/^Your reading list is empty$/i);
    cy.get('@main').findByText(/^View archive$/i);
    cy.get('@main').findByLabelText(/^Filter reading list by text$/i);
    cy.get('@main').findByText(/^Reading list \(0\)$/i);
    cy.get('@main')
      .findByRole('navigation', { name: /^Filter by tag$/i })
      .findByText(/all tags/i);
  });

  it('should filter by text', () => {
    cy.intercept(
      Cypress.config().baseUrl +
        'search/reactions?page=0&per_page=80&status%5B%5D=valid&status%5B%5D=confirmed',
      { fixture: 'search/readingList.json' },
    ).as('readingList');

    cy.intercept(
      Cypress.config().baseUrl +
        'search/reactions?search_fields=article+3&page=0&per_page=80&status%5B%5D=valid&status%5B%5D=confirmed',
      { fixture: 'search/readingListFilterByText.json' },
    ).as('readingListFilteredByText');

    cy.visit('/readinglist');
    cy.wait('@readingList');

    cy.findByRole('main').as('main');
    cy.get('@main')
      .findByLabelText(/^Filter reading list by text$/i)
      .type('article 3');

    cy.wait('@readingListFilteredByText');

    cy.get('@main').findByText('Test Article 1').should('not.exist');
    cy.get('@main').findByText('Test Article 2').should('not.exist');
    cy.get('@main').findByText('Test Article 3');
  });

  it('should be disappeared after click on archive', () => {
    cy.intercept(
      Cypress.config().baseUrl +
        'search/reactions?page=0&per_page=80&status%5B%5D=valid&status%5B%5D=confirmed',
      { fixture: 'search/readingList.json' },
    ).as('readingList');

    cy.intercept(
      { method: 'put', url: '/reading_list_items/**' },
      { body: { current_status: 'valid,confirmed' } },
    ).as('archiveItem');

    cy.visit('/readinglist');
    cy.wait('@readingList');

    cy.findByRole('main').as('main');

    cy.get('@main').findByText('Reading list (3)');
    cy.get('@main').findByText('Test Article 1');
    cy.get('@main').findByText('Test Article 2');
    cy.get('@main').findByText('Test Article 3');

    cy.get('@main')
      .contains('Test Article 1')
      .parents('article')
      .findByRole('button', { name: /^archive$/i })
      .click();

    cy.wait('@archiveItem');

    cy.get('@main').findByText('Reading list (2)');
    cy.get('@main').findByText('Test Article 1').should('not.exist');
    cy.get('@main').findByText('Test Article 2');
    cy.get('@main').findByText('Test Article 3');
  });

  describe('small screens', () => {
    beforeEach(() => {
      cy.intercept(
        Cypress.config().baseUrl +
          'search/reactions?page=0&per_page=80&status%5B%5D=valid&status%5B%5D=confirmed',
        { fixture: 'search/readingList.json' },
      ).as('readingList');

      cy.viewport(BREAKPOINTS.Medium - 1, BREAKPOINTS.Medium);
      cy.visit('/readinglist');
      cy.wait('@readingList');
    });

    it('should load the reading list with items', () => {
      cy.findByRole('main')
        .as('main')
        .findByText(/^Your reading list is empty$/i)
        .should('not.exist');
      cy.get('@main').findByText(/^View archive$/i);
      cy.get('@main').findByLabelText(/Filter reading list by text$/i);
      cy.get('@main').findByText(/^Reading list \(3\)$/);
      cy.get('@main').findByLabelText(/^Filter by tag$/i, {
        selector: 'select',
      });
      cy.get('@main')
        .findByText(/^Filter by tag$/i, { selector: 'legend' })
        .should('not.exist');

      cy.get('@main').findByText('Test Article 1');
      cy.get('@main').findByText('Test Article 2');
      cy.get('@main').findByText('Test Article 3');
    });

    it('should filter by tag', () => {
      cy.intercept(
        Cypress.config().baseUrl +
          'search/reactions?search_fields=&page=0&per_page=80&tag_names%5B%5D=productivity&tag_boolean_mode=all&status%5B%5D=valid&status%5B%5D=confirmed',
        { fixture: 'search/readingListFilterByTagProductivity.json' },
      ).as('filteredReadingList');

      cy.findByRole('main')
        .as('main')
        .findByLabelText('Filter by tag')
        .as('tagFilter')
        .select('productivity');

      cy.wait('@filteredReadingList');

      cy.get('@main').findByText('Test Article 1');
      cy.get('@main').findByText('Test Article 2').should('not.exist');
      cy.get('@main').findByText('Test Article 3');
    });
  });

  describe('large screens', () => {
    beforeEach(() => {
      cy.intercept(
        Cypress.config().baseUrl +
          'search/reactions?page=0&per_page=80&status%5B%5D=valid&status%5B%5D=confirmed',
        { fixture: 'search/readingList.json' },
      ).as('readingList');

      cy.viewport(BREAKPOINTS.Large, 600);
      cy.visit('/readinglist');
      cy.wait('@readingList');
    });

    it('should load the reading list with items', () => {
      cy.findByRole('main')
        .as('main')
        .findByText(/^Your reading list is empty$/i)
        .should('not.exist');
      cy.get('@main').findByText(/^View archive$/i);
      cy.get('@main').findByLabelText(/Filter reading list by text$/i);
      cy.get('@main').findByText(/^Reading list \(3\)$/);
      cy.get('@main').findByRole('navigation', { name: /^Filter by tag$/i });
      cy.get('@main')
        .findByRole('select', { name: /^Filter by tag$/i })
        .should('not.exist');

      cy.get('@main').findByText('Test Article 1');
      cy.get('@main').findByText('Test Article 2');
      cy.get('@main').findByText('Test Article 3');
    });

    it('should filter by tag', () => {
      cy.intercept(
        Cypress.config().baseUrl +
          'search/reactions?search_fields=&page=0&per_page=80&tag_names%5B%5D=productivity&tag_boolean_mode=all&status%5B%5D=valid&status%5B%5D=confirmed',
        { fixture: 'search/readingListFilterByTagProductivity.json' },
      ).as('filteredReadingList');

      cy.findByRole('main')
        .as('main')
        .findByRole('navigation', { name: /^Filter by tag$/i })
        .findByText('#productivity')
        .click();

      cy.wait('@filteredReadingList');

      cy.get('@main').findByText('Test Article 1');
      cy.get('@main').findByText('Test Article 2').should('not.exist');
      cy.get('@main').findByText('Test Article 3');
    });
  });
});

// More on roles, https://admin.forem.com/docs/forem-basics/user-roles
function openCreditsModal() {
  cy.getModal().should('not.exist');
  cy.findByRole('button', { name: 'Adjust balance' }).click();

  return cy.getModal();
}

function verifyAndDismissUserUpdatedMessage(message) {
  cy.findByText(message).should('exist');
  cy.findByRole('button', { name: 'Dismiss message' })
    .should('have.focus')
    .click();
  cy.findByText(message).should('not.exist');
}

describe('Manage User Credits', () => {
  describe('As an admin', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginAndVisit(user, '/admin/users');
        cy.findByRole('link', { name: 'credits_user' }).click();
      });
    });

    it('should add credits', () => {
      cy.findByTestId('user-credits').should('have.text', '100');

      openCreditsModal().within(() => {
        cy.findByRole('combobox', { name: 'Adjust balance' }).select('Add');
        cy.findByRole('spinbutton', {
          name: 'Amount of credits to add or remove',
        }).type('10');
        cy.findByRole('textbox', {
          name: 'Why are you adjusting credits?',
        }).type('some reason');
        cy.findByRole('button', { name: 'Adjust' }).click();
      });

      cy.getModal().should('not.exist');
      verifyAndDismissUserUpdatedMessage('Credits have been added!');
      cy.findByTestId('user-credits').should('have.text', '210');
    });

    it('should remove credits', () => {
      cy.findByTestId('user-credits').should('have.text', '100');

      openCreditsModal().within(() => {
        cy.findByRole('combobox', { name: 'Adjust balance' }).select('Remove');
        cy.findByRole('spinbutton', {
          name: 'Amount of credits to add or remove',
        }).type('1');
        cy.findByRole('textbox', {
          name: 'Why are you adjusting credits?',
        }).type('some reason');
        cy.findByRole('button', { name: 'Adjust' }).click();
      });

      cy.getModal().should('not.exist');
      verifyAndDismissUserUpdatedMessage('Credits have been removed.');
      cy.findByTestId('user-credits').should('have.text', '89');
    });

    it('should not remove more credits than a user has', () => {
      cy.findByTestId('user-credits').should('have.text', '100');

      openCreditsModal().within(() => {
        cy.findByRole('combobox', { name: 'Adjust balance' }).select('Remove');
        cy.findByRole('spinbutton', {
          name: 'Amount of credits to add or remove',
        })
          .as('credits')
          .type('10');
        cy.findByRole('textbox', {
          name: 'Why are you adjusting credits?',
        }).type('some reason');
        cy.findByRole('button', { name: 'Adjust' }).click();
      });

      cy.getModal().should('exist');
      cy.findByTestId('user-credits').should('have.text', '100');
    });

    it('should have correct max credits for adding and removing credits', () => {
      cy.findByTestId('user-credits').should('have.text', '100');

      openCreditsModal().within(() => {
        cy.findByRole('combobox', { name: 'Adjust balance' })
          .as('adjustBalance')
          .select('Add');
        cy.findByRole('spinbutton', {
          name: 'Amount of credits to add or remove',
        })
          .as('creditAmount')
          .should('have.attr', 'max', '9999');

        cy.get('@adjustBalance').select('Remove');
        cy.get('@creditAmount').should('have.attr', 'max', '100');

        cy.get('@adjustBalance').select('Add');
        cy.get('@creditAmount').should('have.attr', 'max', '9999');
      });
    });
  });
});

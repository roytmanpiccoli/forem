// More on roles, https://admin.forem.com/docs/forem-basics/user-roles
function openRolesModal() {
  cy.getModal().should('not.exist');
  cy.findByRole('button', { name: 'Add role' }).click();

  return cy.getModal();
}

function verifyAndDismissUserUpdatedMessage() {
  cy.findByText('User has been updated').should('exist');
  cy.findByRole('button', { name: 'Dismiss message' })
    .should('have.focus')
    .click();
  cy.findByText('User has been updated').should('not.exist');
}

function checkUserStatus(status) {
  cy.findByTestId('user-status').should('have.text', status);
}

describe('Manage User Roles', () => {
  describe('As an admin', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/adminUser.json').as('user');
      cy.get('@user').then((user) => {
        cy.loginUser(user);
      });
    });

    describe('Changing Roles', () => {
      beforeEach(() => {
        cy.visit('/admin/users/2');
      });

      it('should change a role', () => {
        checkUserStatus('Trusted');

        cy.findByRole('button', { name: 'Remove role: Trusted' }).should(
          'exist',
        );
        openRolesModal().within(() => {
          cy.findByRole('combobox', { name: 'Role' }).select('Warn');
          cy.findByRole('textbox', { name: 'Reason' }).type('some reason');
          cy.findByRole('button', { name: 'Add' }).click();
        });

        cy.getModal().should('not.exist');
        verifyAndDismissUserUpdatedMessage();

        cy.findByRole('button', { name: 'Remove role: Warned' }).should(
          'exist',
        );
        checkUserStatus('Warned');
        cy.findByRole('button', { name: 'Remove role: Trusted' }).should(
          'not.exist',
        );
      });

      it('should remove a role', () => {
        checkUserStatus('Trusted');
        cy.findByRole('button', { name: 'Remove role: Trusted' }).click();
        cy.findByRole('button', { name: 'Remove role: Trusted' }).should(
          'not.exist',
        );
        checkUserStatus('Good standing');
      });

      it('should not remove the Super Admin role', () => {
        checkUserStatus('Trusted');

        openRolesModal().within(() => {
          cy.findByRole('combobox', { name: 'Role' }).select('Super Admin');
          cy.findByRole('textbox', { name: 'Reason' }).type('some reason');
          cy.findByRole('button', { name: 'Add' }).click();
        });

        cy.findByRole('button', {
          name: `Super Admin You can't remove this role...`,
        })
          .as('superAdminButton')
          .click()
          .within(() => {
            cy.findByText(`You can't remove this role...`).should('exist');
          });

        cy.get('@superAdminButton').should('exist');
      });
    });

    describe('Adding Roles', () => {
      beforeEach(() => {
        cy.visit('/admin/users/3');
      });

      it('should not add a role if a reason is missing.', () => {
        checkUserStatus('Good standing');
        cy.findByText('No special roles assigned yet.').should('be.visible');

        openRolesModal().within(() => {
          cy.findByRole('combobox', { name: 'Role' }).select('Warn');
          cy.findByRole('button', { name: 'Add' }).click();
          cy.findByRole('button', { name: 'Close' }).click();
        });

        checkUserStatus('Good standing');
        cy.findByRole('button', { name: 'Remove role: Warned' }).should(
          'not.exist',
        );
      });

      it('should add multiple roles', () => {
        cy.findByText('No special roles assigned yet.').should('be.visible');

        openRolesModal().within(() => {
          cy.findByRole('combobox', { name: 'Role' }).select('Warn');
          cy.findByRole('textbox', { name: 'Reason' }).type('some reason');
          cy.findByRole('button', { name: 'Add' }).click();
        });

        cy.getModal().should('not.exist');
        verifyAndDismissUserUpdatedMessage();
        checkUserStatus('Warned');

        cy.findByRole('button', { name: 'Remove role: Warned' }).should(
          'exist',
        );

        openRolesModal().within(() => {
          cy.findByRole('combobox', { name: 'Role' }).select('Comment Suspend');
          cy.findByRole('textbox', { name: 'Reason' }).type('some reason');
          cy.findByRole('button', { name: 'Add' }).click();
        });

        cy.getModal().should('not.exist');
        verifyAndDismissUserUpdatedMessage();
        checkUserStatus('Warned');

        cy.findByRole('button', { name: 'Remove role: Warned' }).should(
          'exist',
        );
        cy.findByRole('button', {
          name: 'Remove role: Comment Suspended',
        }).should('exist');
      });
    });
  });
});

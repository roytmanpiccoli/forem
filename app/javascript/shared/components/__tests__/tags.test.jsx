import fetch from 'jest-fetch-mock';
import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Tags } from '../tags';

fetch.enableMocks();

describe('<Tags />', () => {
  beforeAll(() => {
    const environment = document.createElement('meta');
    environment.setAttribute('name', 'environment');
    document.body.appendChild(environment);
    fetch.resetMocks();
    window.fetch = fetch;
  });

  it('should have no a11y violations', async () => {
    const { container } = render(<Tags defaultValue="defaultValue" listing />);
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  describe('handleKeyDown', () => {
    it('does not call preventDefault on used keyCode', () => {
      // Only one call is being made to /tags/suggest when the comma key is pressed
      // It didn't seem worth it to inspect the whole mock object to ensure the right URL etc.
      fetch.mockResponseOnce('[]');

      const { getByTestId } = render(
        <Tags defaultValue="defaultValue" listing />,
      );

      Event.prototype.preventDefault = jest.fn();

      const tests = [
        { key: 'a', code: '65' },
        { key: '1', code: '49' },
        { key: ',', code: '188' },
        { key: 'Enter', code: '13' },
      ];

      const input = getByTestId('tag-input');

      tests.forEach((eventPayload) => {
        fireEvent.keyDown(input, eventPayload);
      });

      expect(Event.prototype.preventDefault).not.toHaveBeenCalled();
    });
  });
});

import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import userEvent from '@testing-library/user-event';

import '@testing-library/jest-dom';

import { MultiSelectAutocomplete } from '../MultiSelectAutocomplete';

describe('<MultiSelectAutocomplete />', () => {
  it('renders default UI', () => {
    const { container } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        fetchSuggestions={() => {}}
      />,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders with customisation', () => {
    const { container } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        showLabel={false}
        border={false}
        placeholder="Example placeholder"
        inputId="example-input-id"
        fetchSuggestions={() => {}}
      />,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('renders with default values', () => {
    const { container } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        defaultValue={[{ name: 'Default one' }, { name: 'Default two' }]}
        fetchSuggestions={() => {}}
      />,
    );
    expect(container.innerHTML).toMatchSnapshot();
  });

  it('shows static suggestions on focus, if provided', async () => {
    const { getByLabelText, getByText, getByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        staticSuggestions={[{ name: 'one' }, { name: 'two' }]}
        staticSuggestionsHeading="static suggestions heading"
        fetchSuggestions={() => {}}
      />,
    );

    getByLabelText('Example label').focus();

    await waitFor(() =>
      expect(getByText('static suggestions heading')).toBeInTheDocument(),
    );

    expect(getByRole('option', { name: 'one' })).toBeInTheDocument();
    expect(getByRole('option', { name: 'two' })).toBeInTheDocument();
  });

  it('fetches suggestions and displays in dropdown', async () => {
    const mockFetchSuggestions = jest.fn(async () => [
      { name: 'option1' },
      { name: 'option2' },
    ]);

    const { getByLabelText, getByText, getByRole, queryByText } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        staticSuggestions={[{ name: 'one' }, { name: 'two' }]}
        staticSuggestionsHeading="static suggestions heading"
        fetchSuggestions={mockFetchSuggestions}
      />,
    );

    const input = getByLabelText('Example label');
    input.focus();

    await waitFor(() =>
      expect(getByText('static suggestions heading')).toBeInTheDocument(),
    );

    userEvent.type(input, 'a');

    // Check static suggestions are gone and expected options have appeared
    await waitFor(() =>
      expect(queryByText('static suggestions heading')).toBeNull(),
    );
    expect(getByRole('option', { name: 'option1' })).toBeInTheDocument();
    expect(getByRole('option', { name: 'option2' })).toBeInTheDocument();
  });

  it('displays suggestions in a custom template, if provided', async () => {
    const Suggestion = ({ name }) => <span>custom suggestion: {name}</span>;
    const mockFetchSuggestions = jest.fn(async () => [
      { name: 'option1' },
      { name: 'option2' },
    ]);

    const { getByLabelText, getByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        fetchSuggestions={mockFetchSuggestions}
        SuggestionTemplate={Suggestion}
      />,
    );

    const input = getByLabelText('Example label');
    input.focus();
    userEvent.type(input, 'a');

    await waitFor(() =>
      expect(
        getByRole('option', { name: 'custom suggestion: option1' }),
      ).toBeInTheDocument(),
    );
    expect(
      getByRole('option', { name: 'custom suggestion: option2' }),
    ).toBeInTheDocument();
  });

  it('displays search term as an option if no suggestions', async () => {
    const mockFetchSuggestions = jest.fn(async () => []);

    const { getByLabelText, getByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        fetchSuggestions={mockFetchSuggestions}
      />,
    );

    const input = getByLabelText('Example label');
    input.focus();
    userEvent.type(input, 'a');

    await waitFor(() =>
      expect(getByRole('option', { name: 'a' })).toBeInTheDocument(),
    );
  });

  it('selects an option by clicking', async () => {
    const mockFetchSuggestions = jest.fn(async () => [
      { name: 'option1' },
      { name: 'option2' },
    ]);

    const { getByLabelText, getByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        fetchSuggestions={mockFetchSuggestions}
      />,
    );

    const input = getByLabelText('Example label');
    input.focus();
    userEvent.type(input, 'a');

    await waitFor(() =>
      expect(getByRole('option', { name: 'option1' })).toBeInTheDocument(),
    );

    userEvent.click(getByRole('option', { name: 'option1' }));

    // It should now be added to the list of selected items
    await waitFor(() =>
      expect(getByRole('button', { name: 'Edit option1' })).toBeInTheDocument(),
    );
    expect(getByRole('button', { name: 'Remove option1' })).toBeInTheDocument();
  });

  it('selects an option by keyboard enter press', async () => {
    const mockFetchSuggestions = jest.fn(async () => [
      { name: 'option1' },
      { name: 'option2' },
    ]);

    const { getByLabelText, getByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        fetchSuggestions={mockFetchSuggestions}
      />,
    );

    const input = getByLabelText('Example label');
    input.focus();
    userEvent.type(input, 'a');

    await waitFor(() =>
      expect(getByRole('option', { name: 'option1' })).toBeInTheDocument(),
    );

    userEvent.type(input, '{arrowdown}');

    await waitFor(() =>
      expect(getByRole('option', { name: 'option1' })).toHaveAttribute(
        'aria-selected',
        'true',
      ),
    );
    userEvent.type(input, '{enter}');

    // It should now be added to the list of selected items
    await waitFor(() =>
      expect(getByRole('button', { name: 'Edit option1' })).toBeInTheDocument(),
    );
    expect(getByRole('button', { name: 'Remove option1' })).toBeInTheDocument();
  });

  it('should select current text on spacebar press', async () => {
    const mockFetchSuggestions = jest.fn(async () => [
      { name: 'option1' },
      { name: 'option2' },
    ]);

    const { getByLabelText, getByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        fetchSuggestions={mockFetchSuggestions}
      />,
    );

    const input = getByLabelText('Example label');
    input.focus();
    userEvent.type(input, 'example{space}');

    // It should now be added to the list of selected items
    await waitFor(() =>
      expect(getByRole('button', { name: 'Edit example' })).toBeInTheDocument(),
    );
    expect(getByRole('button', { name: 'Remove example' })).toBeInTheDocument();
  });

  it('should select current text on comma press', async () => {
    const mockFetchSuggestions = jest.fn(async () => [
      { name: 'option1' },
      { name: 'option2' },
    ]);

    const { getByLabelText, getByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        fetchSuggestions={mockFetchSuggestions}
      />,
    );

    const input = getByLabelText('Example label');
    input.focus();
    userEvent.type(input, 'example,');

    // It should now be added to the list of selected items
    await waitFor(() =>
      expect(getByRole('button', { name: 'Edit example' })).toBeInTheDocument(),
    );
    expect(getByRole('button', { name: 'Remove example' })).toBeInTheDocument();
  });

  it("doesn't select manual text entry if already selected", async () => {
    const { getByLabelText, getByRole, getAllByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        defaultValue={[{ name: 'example' }]}
        fetchSuggestions={() => []}
      />,
    );

    // Item should already be selected, as passed as a default value
    expect(getByRole('button', { name: 'Edit example' })).toBeInTheDocument();

    const input = getByLabelText('Example label');
    input.focus();
    // Try to select the same value by manually typing
    userEvent.type(input, 'example,');

    expect(input).toHaveValue('');
    // Verify there is still only one selected 'example'
    expect(getAllByRole('button', { name: 'Edit example' })).toHaveLength(1);
  });

  it('displays selections in a custom template, if provided', async () => {
    const Selection = ({ name }) => <button>Selected: {name}</button>;

    const mockFetchSuggestions = jest.fn(async () => [
      { name: 'option1' },
      { name: 'option2' },
    ]);

    const { getByLabelText, getByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        fetchSuggestions={mockFetchSuggestions}
        SelectionTemplate={Selection}
      />,
    );

    const input = getByLabelText('Example label');
    input.focus();
    userEvent.type(input, 'example,');

    // It should now be added to the list of selected items using the custom template
    await waitFor(() =>
      expect(
        getByRole('button', { name: 'Selected: example' }),
      ).toBeInTheDocument(),
    );
  });

  it('edits a selection', async () => {
    const { getByLabelText, getByRole, queryByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        fetchSuggestions={() => []}
        defaultValue={[{ name: 'one' }]}
      />,
    );

    getByRole('button', { name: 'Edit one' }).click();

    // Selection disappears
    await waitFor(() =>
      expect(
        queryByRole('button', { name: 'Edit one' }),
      ).not.toBeInTheDocument(),
    );

    // Input is focused and pre-filled with value
    const input = getByLabelText('Example label');
    await waitFor(() => expect(input).toHaveValue('one'));
    expect(input).toHaveFocus();
  });

  it('passes an edit callback to custom selection template', async () => {
    const Selection = ({ name, onEdit }) => (
      <button onClick={onEdit}>Selected: {name}</button>
    );

    const { getByLabelText, getByRole, queryByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        defaultValue={[{ name: 'one' }]}
        fetchSuggestions={() => []}
        SelectionTemplate={Selection}
      />,
    );

    getByRole('button', { name: 'Selected: one' }).click();

    // Selection disappears
    await waitFor(() =>
      expect(
        queryByRole('button', { name: 'Selected: one' }),
      ).not.toBeInTheDocument(),
    );

    // Input is focused and pre-filled with value
    const input = getByLabelText('Example label');
    await waitFor(() => expect(input).toHaveValue('one'));
    expect(input).toHaveFocus();
  });

  it('deletes a selection', async () => {
    const { getByLabelText, getByRole, queryByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        fetchSuggestions={() => []}
        defaultValue={[{ name: 'one' }]}
      />,
    );

    getByRole('button', { name: 'Remove one' }).click();

    // Selection disappears
    await waitFor(() =>
      expect(
        queryByRole('button', { name: 'Remove one' }),
      ).not.toBeInTheDocument(),
    );

    // Input is re-focused
    expect(getByLabelText('Example label')).toHaveFocus();
  });

  it('passes a deselect callback to custom selection template', async () => {
    const Selection = ({ name, onDeselect }) => (
      <button onClick={onDeselect}>Selected: {name}</button>
    );

    const { getByLabelText, getByRole, queryByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        defaultValue={[{ name: 'one' }]}
        fetchSuggestions={() => []}
        SelectionTemplate={Selection}
      />,
    );

    getByRole('button', { name: 'Selected: one' }).click();

    // Selection disappears
    await waitFor(() =>
      expect(
        queryByRole('button', { name: 'Selected: one' }),
      ).not.toBeInTheDocument(),
    );

    // Input is re-focused
    expect(getByLabelText('Example label')).toHaveFocus();
  });

  it('closes dropdown and selects current input value on blur', async () => {
    const mockFetchSuggestions = jest.fn(async () => [
      { name: 'option1' },
      { name: 'option2' },
    ]);

    const { getByLabelText, getByRole, queryByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        fetchSuggestions={mockFetchSuggestions}
      />,
    );

    const input = getByLabelText('Example label');
    input.focus();
    userEvent.type(input, 'a');

    await waitFor(() =>
      expect(getByRole('option', { name: 'option1' })).toBeInTheDocument(),
    );

    input.blur();

    // Dropdown should no longer be visible
    await waitFor(() =>
      expect(queryByRole('option', { name: 'option1' })).toBeNull(),
    );

    // Text value should be selected
    expect(getByRole('button', { name: 'Edit a' })).toBeInTheDocument();
    expect(getByRole('button', { name: 'Remove a' })).toBeInTheDocument();
  });

  it('clears the input on Escape press', async () => {
    const mockFetchSuggestions = jest.fn(async () => [
      { name: 'option1' },
      { name: 'option2' },
    ]);

    const { getByLabelText, getByRole, queryByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        fetchSuggestions={mockFetchSuggestions}
      />,
    );

    const input = getByLabelText('Example label');
    input.focus();
    userEvent.type(input, 'a');

    await waitFor(() =>
      expect(getByRole('option', { name: 'option1' })).toBeInTheDocument(),
    );

    userEvent.type(input, '{esc}');

    await waitFor(() =>
      expect(queryByRole('option', { name: 'option1' })).toBeNull(),
    );

    expect(input).toHaveValue('');
  });

  it('Edits previous selection (if exists) on backspace press in empty input', async () => {
    const { getByLabelText, getByRole, queryByRole } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        defaultValue={[{ name: 'example' }]}
        fetchSuggestions={() => []}
      />,
    );

    // Selection should be present as passed as a default value
    expect(getByRole('button', { name: 'Edit example' })).toBeInTheDocument();

    const input = getByLabelText('Example label');
    input.focus();
    userEvent.type(input, '{backspace}');

    await waitFor(() => expect(input).toHaveValue('example'));
    expect(queryByRole('button', { name: 'Edit example' })).toBeNull();
  });

  it('Prohibits entering special characters', () => {
    const { getByLabelText } = render(
      <MultiSelectAutocomplete
        labelText="Example label"
        fetchSuggestions={() => []}
      />,
    );

    const input = getByLabelText('Example label');
    userEvent.type(input, '!@£$%^&*()a1');
    expect(input).toHaveValue('a1');
  });

  it('shows a message and prevents selections when maximum is reached', async () => {
    const mockFetchSuggestions = jest.fn(async () => [
      { name: 'option1' },
      { name: 'option2' },
    ]);

    const {
      getByLabelText,
      getByRole,
      queryByText,
      getByText,
      queryAllByRole,
    } = render(
      <MultiSelectAutocomplete
        maxSelections={2}
        defaultValue={[{ name: 'defaultSelection' }]}
        labelText="Example label"
        fetchSuggestions={mockFetchSuggestions}
      />,
    );

    const input = getByLabelText('Example label');
    input.focus();

    // Max selections not yet reached
    expect(queryByText('Only 2 selections allowed')).toBeNull();
    expect(input).toHaveAttribute('aria-disabled', 'false');

    userEvent.type(input, 'example,');

    // Make sure option has been selected
    await waitFor(() => getByRole('button', { name: 'Edit example' }));

    // Check input is in the max reached state
    expect(input).toHaveAttribute('placeholder', '');
    expect(getByText('Only 2 selections allowed')).toBeInTheDocument();
    expect(input).toHaveAttribute('aria-disabled', 'true');

    // Start typing and make sure further options not shown
    userEvent.type(input, 'a');
    expect(queryAllByRole('option')).toHaveLength(0);
    expect(getByText('Only 2 selections allowed')).toBeInTheDocument();

    // Try to select a value by typing a comma
    userEvent.type(input, 'b,');
    // Verify the selection wasn't made, and the text is still in the input
    expect(input).toHaveValue('ab');
  });
});

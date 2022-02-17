import { h } from 'preact';

import '../../../storybook-utilities/designSystem.scss';

export default {
  title: 'Components/Form Elements/Multiline Text Field',
};

export const Default = () => (
  <textarea
    className="crayons-textfield"
    placeholder="This is placeholder..."
  />
);

Default.story = { name: 'default' };

export const Disabled = () => (
  <textarea
    className="crayons-textfield"
    placeholder="This is placeholder..."
    disabled
  >
    Disabled textarea
  </textarea>
);

Disabled.story = { name: 'disabled' };

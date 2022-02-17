// Archive / unarchive button for item list

// NOTE: although this element should clearly be a button and not an anchor,
// I think I've stumbled on a (p)React bug similar to this:
// <https://github.com/facebook/react/issues/9023>
// where if I transform it in a button, `e.preventDefault()` in the parent
// handler or `e.stopPropagation` are just ignored
import { h } from 'preact';
import PropTypes from 'prop-types';
import { ButtonNew as Button } from '@crayons';

export const ItemListItemArchiveButton = ({ text, onClick }) => (
  <Button className="spec__archive-button" onClick={onClick}>
    {text}
  </Button>
);

ItemListItemArchiveButton.propTypes = {
  text: PropTypes.string.isRequired,
  onClick: PropTypes.func.isRequired,
};

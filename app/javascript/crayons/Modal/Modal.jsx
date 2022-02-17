import { h } from 'preact';
import PropTypes from 'prop-types';
import classNames from 'classnames/bind';
import { FocusTrap } from '../../shared/components/focusTrap';
import { defaultChildrenPropTypes } from '../../common-prop-types';
import { ButtonNew as Button } from '@crayons';
import CloseIcon from '@images/x.svg';

export const Modal = ({
  children,
  size,
  className,
  title,
  prompt,
  centered,
  noBackdrop,
  backdropDismissible = false,
  onClose = () => {},
  focusTrapSelector = '.crayons-modal__box',
}) => {
  const classes = classNames('crayons-modal', {
    [`crayons-modal--${size}`]: size && size !== 'medium',
    'crayons-modal--prompt': prompt,
    'crayons-modal--centered': centered && prompt,
    'crayons-modal--bg-dismissible': !noBackdrop && backdropDismissible,
    [className]: className,
  });

  return (
    <FocusTrap
      onDeactivate={onClose}
      clickOutsideDeactivates={backdropDismissible}
      selector={focusTrapSelector}
    >
      <div data-testid="modal-container" className={classes}>
        <div
          role="dialog"
          aria-modal="true"
          aria-label="modal"
          className="crayons-modal__box"
        >
          <header className="crayons-modal__box__header">
            <h2 class="crayons-subtitle-2">{title}</h2>
            <Button
              icon={CloseIcon}
              aria-label="Close"
              className="crayons-modal__dismiss"
              onClick={onClose}
            />
          </header>
          <div className="crayons-modal__box__body">{children}</div>
        </div>
        {!noBackdrop && (
          <div
            data-testid="modal-overlay"
            className="crayons-modal__backdrop"
          />
        )}
      </div>
    </FocusTrap>
  );
};

Modal.displayName = 'Modal';

Modal.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  className: PropTypes.string,
  title: PropTypes.string.isRequired,
  backdrop: PropTypes.bool,
  backdropDismissible: PropTypes.bool,
  prompt: PropTypes.bool,
  centered: PropTypes.bool,
  onClose: PropTypes.func,
  size: PropTypes.oneOf(['small', 'medium', 'large']),
  focusTrapSelector: PropTypes.string,
};

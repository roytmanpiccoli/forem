/*
  global initializeLocalStorageRender, initializeBodyData,
  initializeAllTagEditButtons, initializeUserFollowButts,
  initializeBaseTracking, initializeCommentsPage,
  initializeArticleDate, initializeArticleReactions, initNotifications,
  initializeCommentDate, initializeSettings,
  initializeCommentPreview, initializeRuntimeBanner,
  initializeTimeFixer, initializeDashboardSort,
  initializeArchivedPostFilter, initializeCreditsPage,
  initializeProfileInfoToggle, initializePodcastPlayback,
  initializeVideoPlayback, initializeDrawerSliders, initializeProfileBadgesToggle,
  initializeHeroBannerClose, initializeOnboardingTaskCard, initScrolling,
  nextPage:writable, fetching:writable, done:writable, adClicked:writable,
  initializePaymentPointers, initializeBroadcast, initializeDateHelpers,
  initializeColorPicker, Runtime
*/

function callInitializers() {
  initializeBaseTracking();
  initializePaymentPointers();
  initializeCommentsPage();
  initializeArticleDate();
  initializeArticleReactions();
  initNotifications();
  initializeCommentDate();
  initializeSettings();
  initializeCommentPreview();
  initializeTimeFixer();
  initializeDashboardSort();
  initializeArchivedPostFilter();
  initializeCreditsPage();
  initializeProfileInfoToggle();
  initializeProfileBadgesToggle();
  initializeDrawerSliders();
  initializeHeroBannerClose();
  initializeOnboardingTaskCard();
  initializeDateHelpers();
  initializeColorPicker();
}

function initializePage() {
  initializeLocalStorageRender();
  initializeBodyData();

  var waitingForDataLoad = setInterval(function wait() {
    if (document.body.getAttribute('data-loaded') === 'true') {
      clearInterval(waitingForDataLoad);
      if (document.body.getAttribute('data-user-status') === 'logged-in') {
        initializeBaseUserData();
        initializeAllTagEditButtons();
      }
      initializeBroadcast();
      initializeReadingListIcons();
      initializeSponsorshipVisibility();
      if (document.getElementById('sidebar-additional')) {
        document.getElementById('sidebar-additional').classList.add('showing');
      }
      initializePodcastPlayback();
      initializeVideoPlayback();
    }
  }, 1);

  callInitializers();

  function freezeScrolling(event) {
    event.preventDefault();
  }

  nextPage = 0;
  fetching = false;
  done = false;
  adClicked = false;
  setTimeout(function undone() {
    done = false;
  }, 300);
  if (!initScrolling.called) {
    initScrolling();
  }

  // Initialize data-runtime context to the body data-attribute
  document.body.dataset.runtime = Runtime.currentContext();
}

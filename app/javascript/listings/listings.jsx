import { h, Component } from 'preact';
import { debounceAction } from '../utilities/debounceAction';
import { fetchSearch } from '../utilities/search';
import { Modal } from './components/Modal';
import { AllListings } from './components/AllListings';
import { ListingFilters } from './components/ListingFilters';
import {
  LISTING_PAGE_SIZE,
  updateListings,
  getQueryParams,
  resizeAllMasonryItems,
  getLocation,
} from './utils';

export class Listings extends Component {
  state = {
    listings: [],
    query: '',
    tags: [],
    category: '',
    allCategories: [],
    initialFetch: true,
    currentUserId: null,
    openedListing: null,
    slug: null,
    page: 0,
    showNextPageButton: false,
    isModalOpen: false,
  };

  componentWillMount() {
    const params = getQueryParams();
    const container = document.getElementById('listings-index-container');
    const category = container.dataset.category || '';
    const allCategories = JSON.parse(container.dataset.allcategories || []);
    let tags = [];
    let openedListing = null;
    let slug = null;
    let listings = [];
    let isModalOpen = false;

    if (params.t) {
      tags = params.t.split(',');
    }

    const query = params.q || '';

    if (tags.length === 0 && query === '') {
      listings = JSON.parse(container.dataset.listings);
    }

    if (container.dataset.displayedlisting) {
      openedListing = JSON.parse(container.dataset.displayedlisting);
      ({ slug } = openedListing);
      isModalOpen = true;
    }

    this.debouncedListingSearch = debounceAction(this.handleQuery.bind(this), {
      time: 150,
      config: { leading: true },
    });

    this.setState({
      query,
      tags,
      category,
      allCategories,
      listings,
      openedListing,
      slug,
      isModalOpen,
    });
    this.listingSearch(query, tags, category, slug);
    this.setUser();

    /*
      The width of the columns also changes when the browser is resized
      so we will also call this function on window resize to recalculate
      each grid item's height to avoid content overflow
    */
    window.addEventListener('resize', resizeAllMasonryItems);
  }

  componentDidUpdate() {
    this.triggerMasonry();
  }

  addTag = (e, tag) => {
    e.preventDefault();
    const { query, tags, category } = this.state;
    const newTags = tags;
    if (newTags.indexOf(tag) === -1) {
      newTags.push(tag);
    }
    this.setState({ tags: newTags, page: 0, isModalOpen: false });
    this.listingSearch(query, newTags, category, null);
    window.scroll(0, 0);
  };

  removeTag = (e, tag) => {
    e.preventDefault();
    const { query, tags, category } = this.state;
    const newTags = tags;
    const index = newTags.indexOf(tag);
    if (newTags.indexOf(tag) > -1) {
      newTags.splice(index, 1);
    }
    this.setState({ tags: newTags, page: 0 });
    this.listingSearch(query, newTags, category, null);
  };

  handleKeyPressedOnSelectedTags = (e, tag) => {
    if (e.key === 'Enter') {
      this.removeTag(e, tag);
    }
  };

  selectCategory = (e, cat = '') => {
    e.preventDefault();
    const { query, tags } = this.state;
    this.setState((prevState) => {
      if (prevState.isModalOpen) {
        return { category: cat, page: 0, isModalOpen: false };
      }
      return { category: cat, page: 0 };
    });
    this.listingSearch(query, tags, cat, null);
  };

  handleCloseModal = () => {
    const { query, tags, category } = this.state;
    this.setState({ openedListing: null, page: 0, isModalOpen: false });
    this.setLocation(query, tags, category, null);
  };

  handleOpenModal = (e, listing) => {
    e.preventDefault();
    this.setState({ openedListing: listing, isModalOpen: true });
    window.history.replaceState(
      null,
      null,
      `/listings/${listing.category}/${listing.slug}`,
    );
    this.setLocation(null, null, listing.category, listing.slug);
  };

  handleQuery = (e) => {
    const { tags, category } = this.state;
    this.setState({ query: e.target.value, page: 0 });
    this.listingSearch(e.target.value, tags, category, null);
  };

  clearQuery = () => {
    const { tags, category } = this.state;
    document.getElementById('listings-search').value = '';
    this.setState({ query: '', page: 0 });
    this.listingSearch('', tags, category, null);
  };

  loadNextPage = () => {
    const { query, tags, category, slug, page } = this.state;
    this.setState({ page: page + 1 });
    this.listingSearch(query, tags, category, slug);
  };

  setUser = () => {
    const { currentUserId } = this.state;
    setTimeout(() => {
      if (window.currentUser && currentUserId === null) {
        this.setState({ currentUserId: window.currentUser.id });
      }
    }, 1000);
  };

  triggerMasonry = () => {
    resizeAllMasonryItems();
    setTimeout(resizeAllMasonryItems, 1);
    setTimeout(resizeAllMasonryItems, 3);
  };

  setLocation = (query, tags, category, slug) => {
    const newLocation = getLocation({ query, tags, category, slug });
    window.history.replaceState(null, null, newLocation);
  };

  /**
   * Call search API for Listings
   *
   * @param {string} query - The search term
   * @param {string} tags - The tags selected by the user
   * @param {string} category - The category selected by the user
   * @param {string} slug - The listing's slug
   *
   * @returns {Promise} A promise object with response formatted as JSON.
   */
  listingSearch(query, tags, category, slug) {
    const { page } = this.state;
    const dataHash = {
      category,
      listing_search: query,
      page,
      per_page: LISTING_PAGE_SIZE,
      tags,
      tag_boolean_mode: 'all',
    };

    const responsePromise = fetchSearch('listings', dataHash);
    return responsePromise.then((response) => {
      const listings = response.result;
      const fullListings = updateListings(listings);
      this.setState({
        listings: fullListings,
        initialFetch: false,
        showNextPageButton: listings.length === LISTING_PAGE_SIZE,
      });
      this.setLocation(query, tags, category, slug);
    });
  }

  render() {
    const {
      listings,
      query,
      tags,
      category,
      allCategories,
      currentUserId,
      openedListing,
      showNextPageButton,
      initialFetch,
      isModalOpen,
    } = this.state;

    const shouldRenderModal =
      isModalOpen && openedListing !== null && openedListing !== undefined;

    if (initialFetch) {
      this.triggerMasonry();
    }
    return (
      <div className="crayons-layout crayons-layout--2-cols">
        <ListingFilters
          categories={allCategories}
          category={category}
          onSelectCategory={this.selectCategory}
          onKeyUp={this.debouncedListingSearch}
          onClearQuery={this.clearQuery}
          onRemoveTag={this.removeTag}
          tags={tags}
          onKeyPress={this.handleKeyPressedOnSelectedTags}
          query={query}
        />
        <AllListings
          listings={listings}
          onAddTag={this.addTag}
          onChangeCategory={this.selectCategory}
          currentUserId={currentUserId}
          onOpenModal={this.handleOpenModal}
          showNextPageButton={showNextPageButton}
          loadNextPage={this.loadNextPage}
        />
        {shouldRenderModal && (
          <Modal
            currentUserId={currentUserId}
            onAddTag={this.addTag}
            onClick={this.handleCloseModal}
            onChangeCategory={this.selectCategory}
            onOpenModal={this.handleOpenModal}
            listing={openedListing}
          />
        )}
      </div>
    );
  }
}

Listings.displayName = 'Classified Listings';

import PropTypes from 'prop-types';

export const articleSnippetResultPropTypes = PropTypes.shape({
  body_text: PropTypes.arrayOf(PropTypes.string),
});

export const articlePropTypes = PropTypes.shape({
  id: PropTypes.number.isRequired,
  title: PropTypes.string.isRequired,
  path: PropTypes.string.isRequired,
  cloudinary_video_url: PropTypes.string,
  video_duration_in_minutes: PropTypes.string,
  type_of: PropTypes.oneOf(['podcast_episodes']),
  class_name: PropTypes.oneOf(['PodcastEpisode', 'User', 'Article']),
  flare_tag: PropTypes.shape({
    name: PropTypes.string.isRequired,
    bg_color_hex: PropTypes.string,
    text_color_hex: PropTypes.string,
  }),
  tag_list: PropTypes.arrayOf(PropTypes.string),
  cached_tag_list_array: PropTypes.arrayOf(PropTypes.string),
  podcast: PropTypes.shape({
    slug: PropTypes.string.isRequired,
    title: PropTypes.string.isRequired,
    image_url: PropTypes.string.isRequired,
  }),
  user_id: PropTypes.number.isRequired,
  user: PropTypes.shape({
    username: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
  }),
  organization: PropTypes.shape({
    name: PropTypes.string.isRequired,
    profile_image_90: PropTypes.string.isRequired,
    slug: PropTypes.string.isRequired,
  }),
  highlight: articleSnippetResultPropTypes,
  public_reactions_count: PropTypes.number,
  reactions_count: PropTypes.number,
  comments_count: PropTypes.number,
  reading_time: PropTypes.number,
});

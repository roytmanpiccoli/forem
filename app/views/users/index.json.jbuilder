json.array! @users.each do |user|
  json.extract!(user, :id, :name, :username)

  json.summary           truncate(user.tag_line || t("json.author", community: community_name), length: 100)
  json.profile_image_url user.profile_image_url_for(length: 90)
  json.following         false
end

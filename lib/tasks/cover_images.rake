namespace :cover_images do
  desc "Validate existing cover_image_url and re-resolve cleared ones via AniList"
  task revalidate: :environment do
    puts "Validating cover_image_url reachability..."
    cleared_ids = CoverImages::LinkValidator.call
    puts "Cleared #{cleared_ids.size} invalid cover_image_url(s)."

    cleared_ids.each { |id| CoverImageResolveJob.perform_later(id) }
    puts "Enqueued #{cleared_ids.size} CoverImageResolveJob(s)."
  end
end

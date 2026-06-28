class AddSpotifyArtistIdToArtists < ActiveRecord::Migration[8.1]
  def change
    add_column :artists, :spotify_artist_id, :string
    add_index :artists, :spotify_artist_id, unique: true
  end
end

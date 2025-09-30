class Explore::DataController < Explore::ExploreController

  # GET /data
  def index
    @page_title = 'Download Trefle data on plants and species'
    @page_keywords = 'data, dump, csv, plants, search, species'
  end

end

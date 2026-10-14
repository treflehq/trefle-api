# The data version (DatasetVersion) every API answer states, so that a stored
# response says which state of the data it came from: in the payload's meta
# (CollectionRenderers) and as the X-Trefle-Data-Version header
# (Api::ApiController).
module DatasetVersionMeta
  extend ActiveSupport::Concern

  def dataset_version_meta
    { dataset_version: DatasetVersion.current_version }
  end

  def set_dataset_version_header
    version = DatasetVersion.current_version
    response.headers['X-Trefle-Data-Version'] = version if version
  end
end

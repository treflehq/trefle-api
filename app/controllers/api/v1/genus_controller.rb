class Api::V1::GenusController < Api::ApiController

  FILTERABLE_FIELDS = %w[name slug family_id].freeze
  ORDERABLE_FIELDS = %w[name slug family_id].freeze

  def index
    @collection = collection

    links = collection_links(@collection, name: %i[genus index])

    render_serialized_collection(
      @collection,
      GenusSerializer,
      serializer_options: {
        except: {
          family: [:division_order]
        }
      },
      links: links
    )
  end

  def show
    @resource = Genus.friendly.find(params[:id])

    render_serialized_resource(
      @resource,
      GenusSerializer,
      serializer_options: {
        except: {
          family: [:division_order]
        }
      },
      meta: resource_metadata(@resource)
    )
  end

  def collection
    return @collection if @collection

    @collection = Family.friendly.find(params[:family_id]).genus if params[:family_id]
    @collection ||= Genus.all
    @collection = @collection.preload(family: :division_order)

    @collection = apply_filters(@collection, FILTERABLE_FIELDS)
    @collection = apply_sort(@collection, ORDERABLE_FIELDS, default_sort: { name: :asc })
    # @collection = apply_search(collection)

    @pagy, @collection = pagy(@collection)
    @collection
  end

end

require 'rails_helper'

RSpec.describe Ingester::Converter::Image do

  it 'Can process a good image' do

    hash = {
      scientific_name: 'Aiphanes grandis',
      rank: 'species',
      author: 'Borchs. & Balslev',
      genus: 'Aiphanes',
      status: 'accepted',
      image_url: 'https://tata.co/image.png'
    }

    result = Ingester::Converter::Image.resolve!(hash)
  end

  it 'Dont crash when no images' do
    result = Ingester::Converter::Image.resolve!({})
    expect(result).to eq({})
  end

  # it 'Crash when invalid images' do
  #   expect do
  #     Ingester::Converter::Image.resolve!(
  #       image_url: 'prout'
  #     )
  #   end.to raise_error(Ingester::Converter::Image::ImageException)
  # end
end

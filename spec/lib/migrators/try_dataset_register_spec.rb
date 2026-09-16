require 'rails_helper'

RSpec.describe Migrators::TryDatasetRegister do
  let(:register) { Rails.root.join('tmp/try_datasets_spec.yml') }

  def write(rows)
    File.write(register, rows.map do |id, name, contributor, reference|
      { 'dataset_id' => id, 'dataset_name' => name,
        'contributor' => contributor, 'reference' => reference }
    end.to_yaml)
  end

  after { FileUtils.rm_f(register) }

  it 'seeds a dataset with its credit' do
    write([[1, 'Abisko', 'Johannes Cornelissen', 'Cornelissen, J. H. C. 1996.']])

    expect { described_class.run(path: register, dry_run: false) }.to change(TryDataset, :count).by(1)
    expect(TryDataset.last.credit).to eq('Cornelissen, J. H. C. 1996.')
  end

  # 139 of the 727 datasets ship no citable publication. Credit is still owed,
  # so the contributor and dataset name carry it rather than the row being
  # dropped or the reference invented.
  it 'keeps a dataset that has no reference, crediting whom it can' do
    write([[3, 'Australian Fire Ecology Database', 'Ross Bradstock', nil]])

    result = described_class.run(path: register, dry_run: false)

    expect(result.without_reference).to eq(1)
    expect(TryDataset.last.credit).to eq('Ross Bradstock — Australian Fire Ecology Database')
    expect(TryDataset.without_reference.count).to eq(1)
  end

  # A dataset can cite several publications — dataset 1 cites three — so the
  # register is keyed on the pair, not on the dataset alone.
  it 'keeps every reference a dataset carries' do
    write([[1, 'Abisko', 'Cornelissen', 'First ref'], [1, 'Abisko', 'Cornelissen', 'Second ref']])

    described_class.run(path: register, dry_run: false)

    expect(TryDataset.for_dataset(1).count).to eq(2)
  end

  it 'is replayable: a second run changes nothing' do
    write([[1, 'Abisko', 'Cornelissen', 'First ref']])
    described_class.run(path: register, dry_run: false)

    expect { described_class.run(path: register, dry_run: false) }.not_to change(TryDataset, :count)
    expect(described_class.run(path: register, dry_run: false).unchanged).to eq(1)
  end

  it 'updates a row whose name or contributor changed, without duplicating it' do
    write([[1, 'Abisko', 'Cornelissen', 'First ref']])
    described_class.run(path: register, dry_run: false)
    write([[1, 'Abisko & Sheffield', 'Johannes Cornelissen', 'First ref']])

    expect { described_class.run(path: register, dry_run: false) }.not_to change(TryDataset, :count)
    expect(TryDataset.last.dataset_name).to eq('Abisko & Sheffield')
  end

  it 'never deletes: a dataset absent from a newer export keeps its credit' do
    write([[1, 'Abisko', 'Cornelissen', 'First ref'], [2, 'Other', 'Someone', 'Ref']])
    described_class.run(path: register, dry_run: false)
    write([[1, 'Abisko', 'Cornelissen', 'First ref']])

    expect { described_class.run(path: register, dry_run: false) }.not_to change(TryDataset, :count)
  end

  it 'writes nothing on a dry run but reports what it would do' do
    write([[1, 'Abisko', 'Cornelissen', 'First ref']])

    result = described_class.run(path: register, dry_run: true)

    expect(result.created).to eq(1)
    expect(TryDataset.count).to eq(0)
  end

  describe 'the committed register' do
    it 'is valid UTF-8 and parses' do
      rows = described_class.rows(TryDataset.register_path)

      expect(rows.length).to eq(810)
      expect(rows.count {|r| r[:reference].blank? }).to eq(139)
      expect(rows.map {|r| r[:dataset_id] }.uniq.length).to eq(727)
    end

    it 'credits every row, with a reference or with a name' do
      uncredited = described_class.rows(TryDataset.register_path).reject do |r|
        r[:reference].present? || r[:contributor].present? || r[:dataset_name].present?
      end

      expect(uncredited).to be_empty
    end
  end
end

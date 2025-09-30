class AddTextCatminatColumns < ActiveRecord::Migration[6.0]
  def change
    # capitule de capitules
    # capitule simple
    # cône # rubocop:todo Style/AsciiComments
    # corymbe
    # corymbe de capitules
    # cyathe
    # cyme bipare
    # cyme biscorpioïde # rubocop:todo Style/AsciiComments
    # cyme capituliforme
    # cyme d'épis # rubocop:todo Style/AsciiComments
    # cyme d'ombelles
    # cyme de capitules
    # cyme de glomérules # rubocop:todo Style/AsciiComments
    # cyme multipare
    # cyme unipare hélicoïde # rubocop:todo Style/AsciiComments
    # cyme unipare scorpioïde # rubocop:todo Style/AsciiComments
    # épi d'épillets # rubocop:todo Style/AsciiComments
    # épi de capitules # rubocop:todo Style/AsciiComments
    # épi de cymes triflores # rubocop:todo Style/AsciiComments
    # épi simple # rubocop:todo Style/AsciiComments
    # fleur solitaire latérale # rubocop:todo Style/AsciiComments
    # fleur solitaire terminale
    # glomérules # rubocop:todo Style/AsciiComments
    # glomérules spiciformes # rubocop:todo Style/AsciiComments
    # inflorescence
    # ombelle d'ombellules
    # ombelle simple
    # ombelle simple d'épis # rubocop:todo Style/AsciiComments
    # ombelle simple de capitules
    # panicule d'épillets # rubocop:todo Style/AsciiComments
    # panicule spiciforme
    # racème capituliforme # rubocop:todo Style/AsciiComments
    # racème d'épis # rubocop:todo Style/AsciiComments
    # racème d'ombelles # rubocop:todo Style/AsciiComments
    # racème de capitules # rubocop:todo Style/AsciiComments
    # racème de cymes bipares # rubocop:todo Style/AsciiComments
    # racème de cymes unipares hélicoïdes # rubocop:todo Style/AsciiComments
    # racème de cymes unipares scorpioïdes # rubocop:todo Style/AsciiComments
    # racème de racèmes # rubocop:todo Style/AsciiComments
    # racème simple # rubocop:todo Style/AsciiComments
    # spadice
    # verticille d'ombelles
    add_column :species, :inflorescence_form, :integer
    add_column :species, :inflorescence_type, :integer
    rename_column :species, :inflorescence, :inflorescence_raw

    # androdioïque # rubocop:todo Style/AsciiComments
    # dioïque # rubocop:todo Style/AsciiComments
    # dioïque, monoïque # rubocop:todo Style/AsciiComments
    # gynodioïque # rubocop:todo Style/AsciiComments
    # gynomonoïque # rubocop:todo Style/AsciiComments
    # hermaphrodite
    # hermaphrodite, dioïque # rubocop:todo Style/AsciiComments
    # hermaphrodite, monoïque # rubocop:todo Style/AsciiComments
    # hermaphrodite, monoïque, dioïque # rubocop:todo Style/AsciiComments
    # monoïque # rubocop:todo Style/AsciiComments
    # polygame
    # polygame, dioïque # rubocop:todo Style/AsciiComments
    rename_column :species, :sexuality, :sexuality_raw
    add_column :species, :sexuality, :integer, default: 0, null: false

    # hétérostylée # rubocop:todo Style/AsciiComments
    # homogame
    # protandre
    # protandre, protogyne
    # protogyne
    add_column :species, :maturation_order_raw, :string

    # anémogame # rubocop:todo Style/AsciiComments
    # anémogame, autogame # rubocop:todo Style/AsciiComments
    # apogame
    # autogame
    # autogame, entomogame
    # entomogame
    # entomogame, anémogame # rubocop:todo Style/AsciiComments
    # entomogame, anémogame, autogame # rubocop:todo Style/AsciiComments
    # entomogame, apogame
    # entomogame, autogame
    # hydrogame
    rename_column :species, :pollinisation, :pollinisation_raw
    add_column :species, :pollinisation, :integer, default: 0, null: false

    # akène # rubocop:todo Style/AsciiComments
    # baie
    # capsule
    # caryopse
    # cône # rubocop:todo Style/AsciiComments
    # drupe
    # follicule
    # fruit
    # gousse
    # pyxide
    # samare
    # silique
    rename_column :species, :fruit_shape, :fruit_shape_raw
    add_column :species, :fruit_shape, :integer

    # anémochore # rubocop:todo Style/AsciiComments
    # anémochore, myrmécochore # rubocop:todo Style/AsciiComments
    # autochore
    # barochore
    # dyszoochore
    # endozoochore
    # endozoochore, dyszoochore
    # endozoochorie
    # épizoochore # rubocop:todo Style/AsciiComments
    # hydrochore
    # myrmécochore # rubocop:todo Style/AsciiComments
    rename_column :species, :dissemination, :dissemination_raw
    add_column :species, :dissemination, :integer, default: 0, null: false

    # tver
    # test(hbis)
    # tver-suc
    # hsto(grhi)
    # hros
    # grhi
    # hbis
    # hsto
    # Grhi
    # heri
    # csuf
    # test(hsto)
    # Hbis(Test)
    # Hros
    # cfru
    # hbis(test)
    # hces
    # gbul
    # csuf(grhi)
    # test(hces)
    # Heri
    # Hces
    # And many more...
    add_column :species, :biological_type, :integer
    add_column :species, :biological_type_raw, :string
  end
end

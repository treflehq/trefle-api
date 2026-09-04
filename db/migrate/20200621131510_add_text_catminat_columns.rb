class AddTextCatminatColumns < ActiveRecord::Migration[6.0]
  def change
    # capitule de capitules
    # capitule simple
    # cône
    # corymbe
    # corymbe de capitules
    # cyathe
    # cyme bipare
    # cyme biscorpioïde
    # cyme capituliforme
    # cyme d'épis
    # cyme d'ombelles
    # cyme de capitules
    # cyme de glomérules
    # cyme multipare
    # cyme unipare hélicoïde
    # cyme unipare scorpioïde
    # épi d'épillets
    # épi de capitules
    # épi de cymes triflores
    # épi simple
    # fleur solitaire latérale
    # fleur solitaire terminale
    # glomérules
    # glomérules spiciformes
    # inflorescence
    # ombelle d'ombellules
    # ombelle simple
    # ombelle simple d'épis
    # ombelle simple de capitules
    # panicule d'épillets
    # panicule spiciforme
    # racème capituliforme
    # racème d'épis
    # racème d'ombelles
    # racème de capitules
    # racème de cymes bipares
    # racème de cymes unipares hélicoïdes
    # racème de cymes unipares scorpioïdes
    # racème de racèmes
    # racème simple
    # spadice
    # verticille d'ombelles
    add_column :species, :inflorescence_form, :integer
    add_column :species, :inflorescence_type, :integer
    rename_column :species, :inflorescence, :inflorescence_raw

    # androdioïque
    # dioïque
    # dioïque, monoïque
    # gynodioïque
    # gynomonoïque
    # hermaphrodite
    # hermaphrodite, dioïque
    # hermaphrodite, monoïque
    # hermaphrodite, monoïque, dioïque
    # monoïque
    # polygame
    # polygame, dioïque
    rename_column :species, :sexuality, :sexuality_raw
    add_column :species, :sexuality, :integer, default: 0, null: false

    # hétérostylée
    # homogame
    # protandre
    # protandre, protogyne
    # protogyne
    add_column :species, :maturation_order_raw, :string

    # anémogame
    # anémogame, autogame
    # apogame
    # autogame
    # autogame, entomogame
    # entomogame
    # entomogame, anémogame
    # entomogame, anémogame, autogame
    # entomogame, apogame
    # entomogame, autogame
    # hydrogame
    rename_column :species, :pollinisation, :pollinisation_raw
    add_column :species, :pollinisation, :integer, default: 0, null: false

    # akène
    # baie
    # capsule
    # caryopse
    # cône
    # drupe
    # follicule
    # fruit
    # gousse
    # pyxide
    # samare
    # silique
    rename_column :species, :fruit_shape, :fruit_shape_raw
    add_column :species, :fruit_shape, :integer

    # anémochore
    # anémochore, myrmécochore
    # autochore
    # barochore
    # dyszoochore
    # endozoochore
    # endozoochore, dyszoochore
    # endozoochorie
    # épizoochore
    # hydrochore
    # myrmécochore
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

--------------------------------------------------------
-- Minetest :: Trophies Mod v1.0 (trophies)
--
-- See README.txt for licensing and other information.
-- Copyright (c) 2019, Leslie E. Krause
--
-- ./games/minetest_game/mods/trophies/init.lua
--------------------------------------------------------

minetest.register_node( "trophies:gold_cup", {
	-- original image from https://icons8.com/icon/set/trophy/color
	description = "Gold Cup Trophy",
	drawtype = "mesh",
	mesh = "trophies_goldcup.obj",
	wield_scale = { x = 1.5, y = 1.5, z = 1.5 },
	tiles = {
		"default_wood.png",
		"trophies_polished_gold.png"
	},
	inventory_image = "trophies_goldcup_inv.png",
	wield_image = "trophies_goldcup_inv.png",
	paramtype = "light",
	paramtype2 = "facedir",
	node_placement_prediction = "",
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = { -0.3125, -0.5, -0.1875, 0.3125, 0.125, 0.1875 }
	},
	groups = { snappy = 3, not_in_creative_inventory = 1 },
        sounds = default.node_sound_metal_defaults(),

	on_use = function ( itemstack, player, pointed_thing )
		local data = minetest.deserialize( itemstack:get_metadata( ) ) or { }
		local player_name = player:get_player_name( )

		if data.owner and data.grantor ~= player_name then
			minetest.chat_send_player( player_name, "This trophy has already been awarded to a player!" )
			return itemstack
		end

		local function get_editor_formspec( )
			if not data.owner then
				data.owner = ""
				data.grantor = player_name
				data.oldtime = os.time( )
				data.title = "Achievement of Excellence"
				data.message = "In Recognition of Outstanding Bravery in Competition"
			end

			local output_text = string.format( "%s (awarded to %s)\n\n\"%s\"\n\nPresented on %s by %s",
				data.title, data.owner == default.OWNER_NOBODY and "nobody" or data.owner, data.message, os.date( "%x", data.oldtime ), data.grantor )

			local formspec =
				"size[8,6.5]" ..
				default.gui_bg ..
				default.gui_bg_img ..
				"textarea[0.3,0.4;8,1.5;message;Enter the message to display on the trophy (100 character limit);" .. minetest.formspec_escape( data.message ) .. "]" ..
	               		"label[0.0,2.0;Title:]" ..
				"field[1.1,2.4;3.6,0.25;title;;" .. minetest.formspec_escape( data.title ) .. "]" ..
	               		"label[4.6,2.0;Winner:]" ..
				"field[6.0,2.4;2.3,0.25;owner;;" .. minetest.formspec_escape( data.owner ) .. "]" ..
				"box[0.0,2.8;7.8,2.9;#00000000]" ..
				"textarea[0.5,3.0;7.3,2.5;;" .. minetest.formspec_escape( output_text ) .. ";]" ..
				"button[0.0,6.1;2.0,0.3;preview;Preview]" ..
				"button[6.0,6.1;2.0,0.3;save;Save]"

			return formspec
		end

		minetest.create_form( nil, player_name, get_editor_formspec( ), function ( _, player, fields )
			if fields.save or fields.preview then
				if fields.owner == player_name then
					minetest.chat_send_player( player_name, "You cannot award a trophy to yourself." )
					return
				elseif not string.find( fields.owner, "^[-_A-Za-z0-9]+$" ) then
					minetest.chat_send_player( player_name, "The specified winner is invalid." )
					return
				elseif string.len( fields.message ) < 5 then
					minetest.chat_send_player( player_name, "The specified message is too short." )
					return
				elseif string.len( fields.message ) > 100 then
					minetest.chat_send_player( player_name, "The specified message is too long." )
					return
				elseif string.len( fields.title ) < 5 then
					minetest.chat_send_player( player_name, "The specified title is too short." )
					return
				elseif string.len( fields.title ) > 30 then
					minetest.chat_send_player( player_name, "The specified title is too long." )
					return
				end
			end

			data.owner = fields.owner
			data.title = fields.title
			data.message = fields.message

			if fields.preview then
				minetest.update_form( player_name, get_editor_formspec( ) )

			elseif fields.save then
				data.oldtime = os.time( )
				itemstack:set_metadata( minetest.serialize( data ) )
				player:set_wielded_item( itemstack )

				minetest.chat_send_player( player_name, "The trophy has been inscribed with your new message!" )

				minetest.destroy_form( player_name )
			end
		end )

		return itemstack
	end,

	on_place = function( itemstack, placer, pointed_thing )
		if pointed_thing.type == "object" then return end

		local data = minetest.deserialize( itemstack:get_metadata( ) ) or { }
		local player_name = placer:get_player_name( )

		if not data.owner then
			minetest.chat_send_player( player_name, "This trophy cannot be placed until awarded to a player!" )
			return itemstack
		end

		local new_itemstack = ItemStack( "trophies:gold_cup" )
		new_itemstack:set_metadata( itemstack:get_metadata( ) )	-- used to pass the tropy properties

		return minetest.item_place_node( new_itemstack, placer, pointed_thing )
	end,

	after_place_node = function ( pos, placer, itemstack, pointed_thing )
		local data = minetest.deserialize( itemstack:get_metadata( ) )

		if data then
			local meta = minetest.get_meta( pos )
			meta:set_string( "infotext", string.format( "%s (awarded to %s)\n\n\"%s\"\n\nPresented on %s by %s",
				data.title, data.owner == default.OWNER_NOBODY and "nobody" or data.owner, data.message, os.date( "%x", data.oldtime ), data.grantor ) )
			meta:set_string( "owner", data.owner )
			meta:set_string( "grantor", data.grantor )
			meta:set_string( "title", data.title )
			meta:set_string( "message", data.message )
			meta:set_int( "oldtime", data.oldtime )
		end
	end,

	on_dig = function ( pos, node, player )
		local player_name = player:get_player_name( )

		if not default.is_owner( pos, player ) then
			minetest.record_protection_violation( pos, player_name )
			return
		end

		local player_inv = player:get_inventory( )
		local itemstack = ItemStack( node.name )

		local meta = minetest.get_meta( pos )
		local owner = meta:get_string( "owner" )
		local grantor = meta:get_string( "grantor" )
		local title = meta:get_string( "title" )
		local message = meta:get_string( "message" )
		local oldtime = meta:get_int( "oldtime" )

		local data = { }
		data.owner = owner
		data.grantor = grantor
		data.title = title
		data.message = message
		data.oldtime = oldtime

		itemstack:set_metadata( minetest.serialize( data ) )

--		minetest.handle_node_drops( pos, { node.name }, player )

		if player_inv:room_for_item( "main", itemstack ) then
			player_inv:add_item( "main", itemstack )
		else
			minetest.add_item( player:getpos( ), itemstack )
		end

		minetest.remove_node( pos )
	end,

	on_open = function ( pos, player )
		-- the node can only be placed (and hence opened) once metadata is set
		local meta = minetest.get_meta( pos )
		local owner = meta:get_string( "owner" )
		local grantor = meta:get_string( "grantor" )
		local title = meta:get_string( "title" )
		local message = meta:get_string( "message" )
		local oldtime = meta:get_int( "oldtime" )

		local output_text = string.format( "%s (awarded to %s)\n\n\"%s\"\n\nPresented on %s by %s",
			title, owner == default.OWNER_NOBODY and "nobody" or owner, message, os.date( "%x", oldtime ), grantor )

		local formspec =
			"size[10.0,4.0]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			"box[0.0,0.0;9.8,3.2;#222222FF]" ..
			"image[0.5,0.4;2.2,2.8;trophies_goldcup_big.png]" ..
			"textarea[3.0,0.6;7.0,2.5;;" .. minetest.formspec_escape( output_text ) .. ";]" ..
			"button_exit[4.0,3.6;2.0,0.3;close;Close]"

		return formspec
	end,

	on_close = function ( )
	end,
} )

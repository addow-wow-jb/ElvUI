local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule('UnitFrames');
local _, ns = ...
local ElvUF = ns.oUF

local selectedSpell;
local selectedFilter;
local filters;

local function UpdateFilterGroup()
	if selectedFilter == 'Buff Indicator' then
		local buffs = {};
		for _, value in pairs(E.global.unitframe.buffwatch[E.myclass]) do
			tinsert(buffs, value);
		end		
		
		if not E.global.unitframe.buffwatch[E.myclass] then
			E.global.unitframe.buffwatch[E.myclass] = {};
		end		

		
		E.Options.args.unitframe.args.filters.args.filterGroup = {
			type = 'group',
			name = selectedFilter,
			guiInline = true,
			order = -10,
			childGroups = "select",
			args = {
				addSpellID = {
					order = 1,
					name = L['Add SpellID'],
					desc = L['Add a spell to the filter.'],
					type = 'input',
					get = function(info) return "" end,
					set = function(info, value) 
						if not tonumber(value) then
							E:Print(L["Value must be a number"])					
						elseif not GetSpellInfo(value) then
							E:Print(L["Not valid spell id"])
						else	
							table.insert(E.global.unitframe.buffwatch[E.myclass], {["enabled"] = true, ["id"] = tonumber(value), ["point"] = "TOPRIGHT", ["color"] = {["r"] = 1, ["g"] = 0, ["b"] = 0}, ["anyUnit"] = false})
							UpdateFilterGroup();
							UF:Update_AllFrames();
							selectedSpell = nil;
						end
					end,					
				},
				removeSpellID = {
					order = 2,
					name = L['Remove SpellID'],
					desc = L['Remove a spell from the filter.'],
					type = 'input',
					get = function(info) return "" end,
					set = function(info, value) 
						if not tonumber(value) then
							E:Print(L["Value must be a number"])
						elseif not GetSpellInfo(value) then
							E:Print(L["Not valid spell id"])
						else	
							local match
							for x, y in pairs(E.global.unitframe.buffwatch[E.myclass]) do
								if y["id"] == tonumber(value) then
									match = y
									E.global.unitframe.buffwatch[E.myclass][x] = nil
								end
							end
							if match == nil then
								E:Print(L["Spell not found in list."])
							else
								UpdateFilterGroup()							
							end									
						end		
						
						selectedSpell = nil;
						UpdateFilterGroup();
						UF:Update_AllFrames();
					end,				
				},
				selectSpell = {
					name = L["Select Spell"],
					type = "select",
					order = 3,
					values = function()
						local values = {};
						buffs = {};
						for _, value in pairs(E.global.unitframe.buffwatch[E.myclass]) do
							tinsert(buffs, value);
						end			
						
						for _, spell in pairs(buffs) do
							if spell.id then
								local name = GetSpellInfo(spell.id)
								values[spell.id] = name;
							end
						end
						return values
					end,
					get = function(info) return selectedSpell end,
					set = function(info, value) 
						selectedSpell = value;
						UpdateFilterGroup()
					end,
				},				
			},
		}
		
		local tableIndex
		for i, spell in pairs(E.global.unitframe.buffwatch[E.myclass]) do
			if spell.id == selectedSpell then
				tableIndex = i;
			end
		end
		if selectedSpell and tableIndex then
			local name = GetSpellInfo(selectedSpell)
			E.Options.args.unitframe.args.filters.args.filterGroup.args[name] = {
				name = name..' ('..selectedSpell..')',
				type = 'group',
				get = function(info) return E.global.unitframe.buffwatch[E.myclass][tableIndex][ info[#info] ] end,
				set = function(info, value) E.global.unitframe.buffwatch[E.myclass][tableIndex][ info[#info] ] = value; UF:Update_AllFrames() end,
				order = -10,
				args = {
					enabled = {
						name = L['Enable'],
						order = 1,
						type = 'toggle',
					},
					point = {
						name = L['Anchor Point'],
						order = 2,
						type = 'select',
						values = {
							['TOPLEFT'] = 'TOPLEFT',
							['TOPRIGHT'] = 'TOPRIGHT',
							['BOTTOMLEFT'] = 'BOTTOMLEFT',
							['BOTTOMRIGHT'] = 'BOTTOMRIGHT',
							['LEFT'] = 'LEFT',
							['RIGHT'] = 'RIGHT',
							['TOP'] = 'TOP',
							['BOTTOM'] = 'BOTTOM',
						}
					},
					color = {
						name = L['Color'],
						type = 'color',
						order = 3,
						get = function(info)
							local t = E.global.unitframe.buffwatch[E.myclass][tableIndex][ info[#info] ]
							return t.r, t.g, t.b, t.a
						end,
						set = function(info, r, g, b)
							local t = E.global.unitframe.buffwatch[E.myclass][tableIndex][ info[#info] ]
							t.r, t.g, t.b = r, g, b
							UF:Update_AllFrames()
						end,						
					},
					anyUnit = {
						name = L['Any Unit'],
						order = 4,
						type = 'toggle',					
					},
					onlyShowMissing = {
						name = L['Show Missing'],
						order = 5,
						type = 'toggle',						
					},
				},			
			}
		end
	
		buffs = nil;
	else
		if not selectedFilter or not E.global.unitframe['aurafilters'][selectedFilter] then
			E.Options.args.unitframe.args.filters.args.filterGroup = nil
			E.Options.args.unitframe.args.filters.args.spellGroup = nil
			return
		end
	
		E.Options.args.unitframe.args.filters.args.filterGroup = {
			type = 'group',
			name = selectedFilter,
			guiInline = true,
			order = 10,
			args = {
				addSpell = {
					order = 1,
					name = L['Add Spell'],
					desc = L['Add a spell to the filter.'],
					type = 'input',
					get = function(info) return "" end,
					set = function(info, value) 
						if not E.global.unitframe['aurafilters'][selectedFilter]['spells'][value] then
							E.global.unitframe['aurafilters'][selectedFilter]['spells'][value] = { 
								['enable'] = true,
								['priority'] = 0,
							}
						end
						UpdateFilterGroup();
						UF:Update_AllFrames();
					end,					
				},
				removeSpell = {
					order = 1,
					name = L['Remove Spell'],
					desc = L['Remove a spell from the filter.'],
					type = 'input',
					get = function(info) return "" end,
					set = function(info, value) 
						if G['unitframe']['aurafilters'][selectedFilter] then
							if G['unitframe']['aurafilters'][selectedFilter]['spells'][value] then
								E.global.unitframe['aurafilters'][selectedFilter]['spells'][value].enable = false;
								E:Print(L['You may not remove a spell from a default filter that is not customly added. Setting spell to false instead.'])
							else
								E.global.unitframe['aurafilters'][selectedFilter]['spells'][value] = nil;
							end
						else
							E.global.unitframe['aurafilters'][selectedFilter]['spells'][value] = nil;
						end
						
						UpdateFilterGroup();
						UF:Update_AllFrames();
					end,				
				},		
				filterType = {
					order = 4,
					name = L['Filter Type'],
					desc = L['Set the filter type, blacklisted filters hide any aura on the like and show all else, whitelisted filters show any aura on the filter and hide all else.'],
					type = 'select',
					values = {
						['Whitelist'] = L['Whitelist'],
						['Blacklist'] = L['Blacklist'],
					},
					get = function() return E.global.unitframe['aurafilters'][selectedFilter].type end,
					set = function(info, value) E.global.unitframe['aurafilters'][selectedFilter].type = value; UF:Update_AllFrames(); end,
				},	
				selectSpell = {
					name = L["Select Spell"],
					type = 'select',
					order = -9,
					guiInline = true,
					get = function(info) return selectedSpell end,
					set = function(info, value) selectedSpell = value; UpdateFilterGroup() end,							
					values = function()
						local filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters'][selectedFilter]['spells']) do
							filters[filter] = filter
						end

						return filters
					end,
				},			
			},	
		}
	
		if not selectedSpell or not E.global.unitframe['aurafilters'][selectedFilter]['spells'][selectedSpell] then
			E.Options.args.unitframe.args.filters.args.spellGroup = nil
			return
		end
		
		E.Options.args.unitframe.args.filters.args.spellGroup = {
			type = "group",
			name = selectedSpell,
			order = 15,
			guiInline = true,
			args = {
				enable = {
					name = L["Enable"],
					type = "toggle",
					get = function() return E.global.unitframe['aurafilters'][selectedFilter]['spells'][selectedSpell].enable end,
					set = function(info, value) E.global.unitframe['aurafilters'][selectedFilter]['spells'][selectedSpell].enable = value; UpdateFilterGroup(); UF:Update_AllFrames(); end
				},
				priority = {
					name = L["Priority"],
					type = "range",
					get = function() return E.global.unitframe['aurafilters'][selectedFilter]['spells'][selectedSpell].priority end,
					set = function(info, value) E.global.unitframe['aurafilters'][selectedFilter]['spells'][selectedSpell].priority = value; UpdateFilterGroup(); UF:Update_AllFrames(); end,
					min = 0, max = 10, step = 1,
					desc = L["Set the priority order of the spell, please note that prioritys are only used for the raid debuff module, not the standard buff/debuff module. If you want to disable set to zero."],
				},			
			},
		}
		
	end
end

E.Options.args.unitframe = {
	type = "group",
	name = L["UnitFrames"],
	childGroups = "tree",
	get = function(info) return E.db.unitframe[ info[#info] ] end,
	set = function(info, value) E.db.unitframe[ info[#info] ] = value end,
	args = {
		enable = {
			order = 1,
			type = "toggle",
			name = L["Enable"],
			get = function(info) return E.private.unitframe.enable end,
			set = function(info, value) E.private.unitframe.enable = value; StaticPopup_Show("PRIVATE_RL") end
		},
		moveuf = {
			order = 2,
			type = 'execute',
			name = L['Move UnitFrames'],
			func = function() E:MoveUI(true, 'unitframes'); end,
		},
		resetuf = {
			order = 3,
			type = 'execute',
			name = L['Reset Positions'],
			func = function() ElvUF:ResetUF() end,
		},
		general = {
			order = 200,
			type = 'group',
			name = L['General'],
			guiInline = true,
			disabled = function() return not E.private.unitframe.enable end,
			set = function(info, value) E.db.unitframe[ info[#info] ] = value; UF:Update_AllFrames() end,
			args = {
				generalGroup = {
					order = 1,
					type = 'group',
					guiInline = true,
					name = L['General'],
					args = {
						disableBlizzard = {
							order = 1,
							name = L['Disable Blizzard'],
							desc = L['Disables the blizzard party/raid frames.'],
							type = 'toggle',
							get = function(info) return E.private.unitframe[ info[#info] ] end,
							set = function(info, value) E.private["unitframe"][ info[#info] ] = value; StaticPopup_Show("PRIVATE_RL") end
						},
						OORAlpha = {
							order = 2,
							name = L['OOR Alpha'],
							desc = L['The alpha to set units that are out of range to.'],
							type = 'range',
							min = 0, max = 1, step = 0.01,
						},
						debuffHighlighting = {
							order = 3,
							name = L['Debuff Highlighting'],
							desc = L['Color the unit healthbar if there is a debuff that can be dispelled by you.'],
							type = 'toggle',
						},
						smartRaidFilter = {
							order = 4,
							name = L['Smart Raid Filter'],
							desc = L['Override any custom visibility setting in certain situations, EX: Only show groups 1 and 2 inside a 10 man instance.'],
							type = 'toggle',
							set = function(info, value) E.db.unitframe[ info[#info] ] = value; UF:UpdateAllHeaders() end
						},
					},
				},
				barGroup = {
					order = 2,
					type = 'group',
					guiInline = true,
					name = L['Bars'],
					args = {
						smoothbars = {
							type = 'toggle',
							order = 2,
							name = L['Smooth Bars'],
							desc = L['Bars will transition smoothly.'],	
							set = function(info, value) E.db.unitframe[ info[#info] ] = value; UF:Update_AllFrames(); end,
						},
						statusbar = {
							type = "select", dialogControl = 'LSM30_Statusbar',
							order = 3,
							name = L["StatusBar Texture"],
							desc = L["Main statusbar texture."],
							values = AceGUIWidgetLSMlists.statusbar,			
							set = function(info, value) E.db.unitframe[ info[#info] ] = value; UF:Update_StatusBars() end,
						},	
					},
				},
				fontGroup = {
					order = 3,
					type = 'group',
					guiInline = true,
					name = L['Fonts'],
					args = {
						font = {
							type = "select", dialogControl = 'LSM30_Font',
							order = 4,
							name = L["Default Font"],
							desc = L["The font that the unitframes will use."],
							values = AceGUIWidgetLSMlists.font,
							set = function(info, value) E.db.unitframe[ info[#info] ] = value; UF:Update_FontStrings() end,
						},
						fontsize = {
							order = 5,
							name = L["Font Size"],
							desc = L["Set the font size for unitframes."],
							type = "range",
							min = 6, max = 22, step = 1,
							set = function(info, value) E.db.unitframe[ info[#info] ] = value; UF:Update_FontStrings() end,
						},	
						fontoutline = {
							order = 6,
							name = L["Font Outline"],
							desc = L["Set the font outline."],
							type = "select",
							values = {
								['NONE'] = L['None'],
								['OUTLINE'] = 'OUTLINE',
								['MONOCHROME'] = 'MONOCHROME',
								['THICKOUTLINE'] = 'THICKOUTLINE',
							},
							set = function(info, value) E.db.unitframe[ info[#info] ] = value; UF:Update_FontStrings() end,
						},	
					},
				},
				allColorsGroup = {
					order = 4,
					type = 'group',
					guiInline = true,
					name = L['Colors'],
					get = function(info) return E.db.unitframe.colors[ info[#info] ] end,
					set = function(info, value) E.db.unitframe.colors[ info[#info] ] = value; UF:Update_AllFrames() end,					
					args = {
						healthclass = {
							order = 1,
							type = 'toggle',
							name = L['Class Health'],
							desc = L['Color health by classcolor or reaction.'],
						},
						powerclass = {
							order = 2,
							type = 'toggle',
							name = L['Class Power'],
							desc = L['Color power by classcolor or reaction.'],
						},		
						colorhealthbyvalue = {
							order = 3,
							type = 'toggle',
							name = L['Health By Value'],
							desc = L['Color health by ammount remaining.'],				
						},
						customhealthbackdrop = {
							order = 4,
							type = 'toggle',
							name = L['Custom Health Backdrop'],
							desc = L['Use the custom health backdrop color instead of a multiple of the main health color.'],						
						},
						classbackdrop = {
							order = 5,
							type = 'toggle',
							name = L['Class Backdrop'],
							desc = L['Color the health backdrop by class or reaction.'],
						},
						classNames = {
							order = 6,
							type = 'toggle',
							name = L['Class Names'],
							desc = L['Color the name text by class or reaction.'],
						},						
						colorsGroup = {
							order = 7,
							type = 'group',
							guiInline = true,
							name = HEALTH,
							get = function(info)
								local t = E.db.unitframe.colors[ info[#info] ]
								return t.r, t.g, t.b, t.a
							end,
							set = function(info, r, g, b)
								E.db.general[ info[#info] ] = {}
								local t = E.db.unitframe.colors[ info[#info] ]
								t.r, t.g, t.b = r, g, b
								UF:Update_AllFrames()
							end,
							args = {
								health = {
									order = 1,
									type = 'color',
									name = L['Health'],
								},
								health_backdrop = {
									order = 2,
									type = 'color',
									name = L['Health Backdrop'],
								},			
								tapped = {
									order = 3,
									type = 'color',
									name = L['Tapped'],
								},
								disconnected = {
									order = 4,
									type = 'color',
									name = L['Disconnected'],
								},	
							},
						},
						powerGroup = {
							order = 8,
							type = 'group',
							guiInline = true,
							name = L['Powers'],
							get = function(info)
								local t = E.db.unitframe.colors.power[ info[#info] ]
								return t.r, t.g, t.b, t.a
							end,
							set = function(info, r, g, b)
								E.db.general[ info[#info] ] = {}
								local t = E.db.unitframe.colors.power[ info[#info] ]
								t.r, t.g, t.b = r, g, b
								UF:Update_AllFrames()
							end,	
							args = {
								MANA = {
									order = 1,
									name = MANA,
									type = 'color',
								},
								RAGE = {
									order = 2,
									name = RAGE,
									type = 'color',
								},	
								FOCUS = {
									order = 3,
									name = FOCUS,
									type = 'color',
								},	
								ENERGY = {
									order = 4,
									name = ENERGY,
									type = 'color',
								},		
								RUNIC_POWER = {
									order = 5,
									name = RUNIC_POWER,
									type = 'color',
								},									
							},
						},
						reactionGroup = {
							order = 9,
							type = 'group',
							guiInline = true,
							name = L['Reactions'],
							get = function(info)
								local t = E.db.unitframe.colors.reaction[ info[#info] ]
								return t.r, t.g, t.b, t.a
							end,
							set = function(info, r, g, b)
								E.db.general[ info[#info] ] = {}
								local t = E.db.unitframe.colors.reaction[ info[#info] ]
								t.r, t.g, t.b = r, g, b
								UF:Update_AllFrames()
							end,	
							args = {
								BAD = {
									order = 1,
									name = L['Bad'],
									type = 'color',
								},	
								NEUTRAL = {
									order = 2,
									name = L['Neutral'],
									type = 'color',
								},	
								GOOD = {
									order = 3,
									name = L['Good'],
									type = 'color',
								},									
							},
						},						
					},
				},
			},
		},
		filters = {
			type = 'group',
			name = L['Filters'],
			order = -10, --Always Last Hehehe
			args = {
				createFilter = {
					order = 1,
					name = L['Create Filter'],
					desc = L['Create a filter, once created a filter can be set inside the buffs/debuffs section of each unit.'],
					type = 'input',
					get = function(info) return "" end,
					set = function(info, value) 
						E.global.unitframe['aurafilters'][value] = {};
						E.global.unitframe['aurafilters'][value]['spells'] = {};
					end,					
				},
				deleteFilter = {
					type = 'input',
					order = 2,
					name = L['Delete Filter'],
					desc = L['Delete a created filter, you cannot delete pre-existing filters, only custom ones.'],
					get = function(info) return "" end,
					set = function(info, value) 
						if G['unitframe']['aurafilters'][value] then
							E:Print(L["You can't remove a pre-existing filter."])
						else
							E.global.unitframe['aurafilters'][value] = nil;
							selectedFilter = nil;
							selectedSpell = nil;
							E.Options.args.unitframe.args.filters.args.filterGroup = nil;
						end
					end,				
				},
				selectFilter = {
					order = 3,
					type = 'select',
					name = L['Select Filter'],
					get = function(info) return selectedFilter end,
					set = function(info, value) if value == '' then selectedFilter = nil; selectedSpell = nil; else selectedFilter = value end; UpdateFilterGroup() end,							
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						
						filters['Buff Indicator'] = L['Buff Indicator']
						return filters
					end,
				},
			},
		},
	},
}


local textFormats = {
	['current-percent'] = L['Current - Percent'],
	['current-max'] = L['Current - Max'],
	['current'] = L['Current'],
	['percent'] = L['Percent'],
	['deficit'] = L['Deficit'],
	['blank'] = L['Blank'],
};

local fillValues = {
	['fill'] = L['Filled'],
	['spaced'] = L['Spaced'],
};

local positionValues = {
	TOPLEFT = 'TOPLEFT',
	LEFT = 'LEFT',
	BOTTOMLEFT = 'BOTTOMLEFT',
	RIGHT = 'RIGHT',
	TOPRIGHT = 'TOPRIGHT',
	BOTTOMRIGHT = 'BOTTOMRIGHT',
	CENTER = 'CENTER',
	TOP = 'TOP',
	BOTTOM = 'BOTTOM',
};

local lengthValues = {
	["SHORT"] = L["Short"],
	["MEDIUM"] = L["Medium"],
	["LONG"] = L["Long"],
	["LONGLEVEL"] = L["Long (Include Level)"],
};

local auraAnchors = {
	TOPLEFT = 'TOPLEFT',
	LEFT = 'LEFT',
	BOTTOMLEFT = 'BOTTOMLEFT',
	RIGHT = 'RIGHT',
	TOPRIGHT = 'TOPRIGHT',
	BOTTOMRIGHT = 'BOTTOMRIGHT',
};

local petAnchors = {
	TOPLEFT = 'TOPLEFT',
	LEFT = 'LEFT',
	BOTTOMLEFT = 'BOTTOMLEFT',
	RIGHT = 'RIGHT',
	TOPRIGHT = 'TOPRIGHT',
	BOTTOMRIGHT = 'BOTTOMRIGHT',
	TOP = 'TOP',
	BOTTOM = 'BOTTOM',
};

local filters = {};

--Player
E.Options.args.unitframe.args.player = {
	name = L['Player Frame'],
	type = 'group',
	order = 300,
	childGroups = "select",
	get = function(info) return E.db.unitframe.units['player'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['player'][ info[#info] ] = value; UF:CreateAndUpdateUF('player') end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		copyFrom = {
			type = 'select',
			order = 2,
			name = L['Copy From'],
			desc = L['Select a unit to copy settings from.'],
			values = UF['handledunits'],
			set = function(info, value) UF:MergeUnitSettings(value, 'player'); end,
		},
		resetSettings = {
			type = 'execute',
			order = 3,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('player') end,
		},
		width = {
			order = 4,
			name = L['Width'],
			type = 'range',
			min = 50, max = 500, step = 1,
			set = function(info, value) 
				if E.db.unitframe.units['player'].castbar.width == E.db.unitframe.units['player'][ info[#info] ] then
					E.db.unitframe.units['player'].castbar.width = value;
				end
				
				E.db.unitframe.units['player'][ info[#info] ] = value; 
				UF:CreateAndUpdateUF('player');
			end,
		},
		height = {
			order = 5,
			name = L['Height'],
			type = 'range',
			min = 10, max = 250, step = 1,
		},	
		lowmana = {
			order = 6,
			name = L['Low Mana Threshold'],
			desc = L['When you mana falls below this point, text will flash on the player frame.'],
			type = 'range',
			min = 0, max = 100, step = 1,
		},
		combatfade = {
			order = 7,
			name = L['Combat Fade'],
			desc = L['Fade the unitframe when out of combat, not casting, no target exists.'],
			type = 'toggle',
			set = function(info, value) E.db.unitframe.units['player'][ info[#info] ] = value; UF:CreateAndUpdateUF('player'); UF:CreateAndUpdateUF('pet') end,
		},
		healPrediction = {
			order = 8,
			name = L['Heal Prediction'],
			desc = L['Show a incomming heal prediction bar on the unitframe. Also display a slightly different colored bar for incoming overheals.'],
			type = 'toggle',
		},
		restIcon = {
			order = 9,
			name = L['Rest Icon'],
			desc = L['Display the rested icon on the unitframe.'],
			type = 'toggle',
		},
		health = {
			order = 100,
			type = 'group',
			name = L['Health'],
			get = function(info) return E.db.unitframe.units['player']['health'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['player']['health'][ info[#info] ] = value; UF:CreateAndUpdateUF('player') end,
			args = {
				text = {
					type = 'toggle',
					order = 1,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 2,
					name = L['Text Format'],
					values = textFormats,
				},
				position = {
					type = 'select',
					order = 3,
					name = L['Position'],
					values = positionValues,
				},
			},
		},
		power = {
			order = 200,
			type = 'group',
			name = L['Power'],
			get = function(info) return E.db.unitframe.units['player']['power'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['player']['power'][ info[#info] ] = value; UF:CreateAndUpdateUF('player') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},			
				text = {
					type = 'toggle',
					order = 2,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 3,
					name = L['Text Format'],
					values = textFormats,
				},
				width = {
					type = 'select',
					order = 4,
					name = L['Width'],
					values = fillValues,
				},
				height = {
					type = 'range',
					name = L['Height'],
					order = 5,
					min = 2, max = 50, step = 1,
				},
				offset = {
					type = 'range',
					name = L['Offset'],
					desc = L['Offset of the powerbar to the healthbar, set to 0 to disable.'],
					order = 6,
					min = 0, max = 20, step = 1,
				},
				hideonnpc = {
					type = 'toggle',
					order = 7,
					name = L['Text Toggle On NPC'],
					desc = L['Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point.'],
				},
				position = {
					type = 'select',
					order = 8,
					name = L['Position'],
					values = positionValues,
				},		
			},
		},	
		altpower = {
			order = 300,
			type = 'group',
			name = L['Alt-Power'],
			get = function(info) return E.db.unitframe.units['player']['altpower'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['player']['altpower'][ info[#info] ] = value; UF:CreateAndUpdateUF('player') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				width = {
					type = 'range',
					order = 2,
					name = L['Width'],
					min = 15, max = 550, step = 1,
				},
				height = {
					type = 'range',
					name = L['Height'],
					order = 3,
					min = 5, max = 100, step = 1,
				},
			},
		},	
		name = {
			order = 400,
			type = 'group',
			name = L['Name'],
			get = function(info) return E.db.unitframe.units['player']['name'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['player']['name'][ info[#info] ] = value; UF:CreateAndUpdateUF('player') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		portrait = {
			order = 500,
			type = 'group',
			name = L['Portrait'],
			get = function(info) return E.db.unitframe.units['player']['portrait'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['player']['portrait'][ info[#info] ] = value; UF:CreateAndUpdateUF('player') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				width = {
					type = 'range',
					order = 2,
					name = L['Width'],
					min = 15, max = 150, step = 1,
				},
				overlay = {
					type = 'toggle',
					name = L['Overlay'],
					desc = L['Overlay the healthbar'],
					order = 3,
				},
				camDistanceScale = {
					type = 'range',
					name = L['Camera Distance Scale'],
					desc = L['How far away the portrait is from the camera.'],
					order = 4,
					min = 0.01, max = 4, step = 0.01,
				},
			},
		},	
		buffs = {
			order = 600,
			type = 'group',
			name = L['Buffs'],
			get = function(info) return E.db.unitframe.units['player']['buffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['player']['buffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('player') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['DEBUFFS'] = L['Debuffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 9,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},	
				useFilter = {
					order = 10,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
				showPlayerOnly = {
					order = 11,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},	
				durationLimit = {
					order = 12,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		debuffs = {
			order = 700,
			type = 'group',
			name = L['Debuffs'],
			get = function(info) return E.db.unitframe.units['player']['debuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['player']['debuffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('player') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['BUFFS'] = L['Buffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},		
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},	
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},				
			},
		},	
		castbar = {
			order = 800,
			type = 'group',
			name = L['Castbar'],
			get = function(info) return E.db.unitframe.units['player']['castbar'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['player']['castbar'][ info[#info] ] = value; UF:CreateAndUpdateUF('player') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},	
				matchsize = {
					order = 2,
					type = 'execute',
					name = L['Match Frame Width'],
					func = function() E.db.unitframe.units['player']['castbar']['width'] = E.db.unitframe.units['player']['width']; UF:CreateAndUpdateUF('player') end,
				},			
				forceshow = {
					order = 3,
					name = SHOW..' / '..HIDE,
					func = function() 
						local castbar = ElvUF_Player.Castbar
						if not castbar.oldHide then
							castbar.oldHide = castbar.Hide
							castbar.Hide = castbar.Show
							castbar:Show()
						else
							castbar.Hide = castbar.oldHide
							castbar.oldHide = nil
							castbar:Hide()						
						end
					end,
					type = 'execute',
				},
				width = {
					order = 4,
					name = L['Width'],
					type = 'range',
					min = 50, max = 600, step = 1,
				},
				height = {
					order = 5,
					name = L['Height'],
					type = 'range',
					min = 10, max = 85, step = 1,
				},		
				icon = {
					order = 6,
					name = L['Icon'],
					type = 'toggle',
				},
				xOffset = {
					order = 7,
					name = L['X Offset'],
					type = 'range',
					min = -E.screenwidth, max = E.screenwidth, step = 1,
				},
				yOffset = {
					order = 8,
					name = L['Y Offset'],
					type = 'range',
					min = -E.screenheight, max = E.screenheight, step = 1,
				},				
				latency = {
					order = 9,
					name = L['Latency'],
					type = 'toggle',				
				},
				color = {
					order = 10,
					type = 'color',
					name = L['Color'],
					get = function(info)
						local t = E.db.unitframe.units['player']['castbar'][ info[#info] ]
						return t.r, t.g, t.b, t.a
					end,
					set = function(info, r, g, b)
						E.db.general[ info[#info] ] = {}
						local t = E.db.unitframe.units['player']['castbar'][ info[#info] ]
						t.r, t.g, t.b = r, g, b
						UF:CreateAndUpdateUF('player')
					end,													
				},
				interruptcolor = {
					order = 11,
					type = 'color',
					name = L['Interrupt Color'],
					get = function(info)
						local t = E.db.unitframe.units['player']['castbar'][ info[#info] ]
						return t.r, t.g, t.b, t.a
					end,
					set = function(info, r, g, b)
						E.db.general[ info[#info] ] = {}
						local t = E.db.unitframe.units['player']['castbar'][ info[#info] ]
						t.r, t.g, t.b = r, g, b
						UF:CreateAndUpdateUF('player')
					end,					
				},
				format = {
					order = 12,
					type = 'select',
					name = L['Format'],
					values = {
						['CURRENTMAX'] = L['Current / Max'],
						['CURRENT'] = L['Current'],
						['REMAINING'] = L['Remaining'],
					},
				},
				ticks = {
					order = 13,
					type = 'toggle',
					name = L['Ticks'],
					desc = L['Display tick marks on the castbar for channelled spells. This will adjust automatically for spells like Drain Soul and add additional ticks based on haste.'],
				},
				spark = {
					order = 14,
					type = 'toggle',
					name = L['Spark'],
					desc = L['Display a spark texture at the end of the castbar statusbar to help show the differance between castbar and backdrop.'],
				},
				displayTarget = {
					order = 15,
					type = "toggle",
					name = L["Display Target"],
					desc = L["Display the target of the cast on the castbar."],
				},
			},
		},
		classbar = {
			order = 1000,
			type = 'group',
			name = L['Classbar'],
			get = function(info) return E.db.unitframe.units['player']['classbar'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['player']['classbar'][ info[#info] ] = value; UF:CreateAndUpdateUF('player') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				height = {
					type = 'range',
					order = 2,
					name = L['Height'],
					min = 5, max = 15, step = 1,
				},	
				fill = {
					type = 'select',
					order = 3,
					name = L['Fill'],
					values = fillValues,
				},				
			},
		},
	},
}

--Target
E.Options.args.unitframe.args.target = {
	name = L['Target Frame'],
	type = 'group',
	order = 400,
	childGroups = "select",
	get = function(info) return E.db.unitframe.units['target'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['target'][ info[#info] ] = value; UF:CreateAndUpdateUF('target') end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		copyFrom = {
			type = 'select',
			order = 2,
			name = L['Copy From'],
			desc = L['Select a unit to copy settings from.'],
			values = UF['handledunits'],
			set = function(info, value) UF:MergeUnitSettings(value, 'target'); end,
		},
		resetSettings = {
			type = 'execute',
			order = 3,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('target') end,
		},		
		width = {
			order = 4,
			name = L['Width'],
			type = 'range',
			min = 50, max = 500, step = 1,
			set = function(info, value) 
				if E.db.unitframe.units['target'].castbar.width == E.db.unitframe.units['target'][ info[#info] ] then
					E.db.unitframe.units['target'].castbar.width = value;
				end
				
				E.db.unitframe.units['target'][ info[#info] ] = value; 
				UF:CreateAndUpdateUF('target');
			end,			
		},
		height = {
			order = 5,
			name = L['Height'],
			type = 'range',
			min = 10, max = 250, step = 1,
		},	
		healPrediction = {
			order = 6,
			name = L['Heal Prediction'],
			desc = L['Show a incomming heal prediction bar on the unitframe. Also display a slightly different colored bar for incoming overheals.'],
			type = 'toggle',
		},		
		health = {
			order = 100,
			type = 'group',
			name = L['Health'],
			get = function(info) return E.db.unitframe.units['target']['health'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['target']['health'][ info[#info] ] = value; UF:CreateAndUpdateUF('target') end,
			args = {
				text = {
					type = 'toggle',
					order = 1,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 2,
					name = L['Text Format'],
					values = textFormats,
				},
				position = {
					type = 'select',
					order = 3,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		power = {
			order = 200,
			type = 'group',
			name = L['Power'],
			get = function(info) return E.db.unitframe.units['target']['power'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['target']['power'][ info[#info] ] = value; UF:CreateAndUpdateUF('target') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},			
				text = {
					type = 'toggle',
					order = 2,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 3,
					name = L['Text Format'],
					values = textFormats,
				},
				width = {
					type = 'select',
					order = 4,
					name = L['Width'],
					values = fillValues,
				},
				height = {
					type = 'range',
					name = L['Height'],
					order = 5,
					min = 2, max = 50, step = 1,
				},
				offset = {
					type = 'range',
					name = L['Offset'],
					desc = L['Offset of the powerbar to the healthbar, set to 0 to disable.'],
					order = 6,
					min = 0, max = 20, step = 1,
				},
				hideonnpc = {
					type = 'toggle',
					order = 7,
					name = L['Text Toggle On NPC'],
					desc = L['Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point.'],
				},
				position = {
					type = 'select',
					order = 8,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},	
		name = {
			order = 300,
			type = 'group',
			name = L['Name'],
			get = function(info) return E.db.unitframe.units['target']['name'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['target']['name'][ info[#info] ] = value; UF:CreateAndUpdateUF('target') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		portrait = {
			order = 400,
			type = 'group',
			name = L['Portrait'],
			get = function(info) return E.db.unitframe.units['target']['portrait'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['target']['portrait'][ info[#info] ] = value; UF:CreateAndUpdateUF('target') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				width = {
					type = 'range',
					order = 2,
					name = L['Width'],
					min = 15, max = 150, step = 1,
				},
				overlay = {
					type = 'toggle',
					name = L['Overlay'],
					desc = L['Overlay the healthbar'],
					order = 3,
				},
				camDistanceScale = {
					type = 'range',
					name = L['Camera Distance Scale'],
					desc = L['How far away the portrait is from the camera.'],
					order = 4,
					min = 0.01, max = 4, step = 0.01,
				},				
			},
		},	
		buffs = {
			order = 500,
			type = 'group',
			name = L['Buffs'],
			get = function(info) return E.db.unitframe.units['target']['buffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['target']['buffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('target') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['DEBUFFS'] = L['Debuffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},				
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},		
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},	
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		debuffs = {
			order = 600,
			type = 'group',
			name = L['Debuffs'],
			get = function(info) return E.db.unitframe.units['target']['debuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['target']['debuffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('target') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['BUFFS'] = L['Buffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},	
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		castbar = {
			order = 700,
			type = 'group',
			name = L['Castbar'],
			get = function(info) return E.db.unitframe.units['target']['castbar'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['target']['castbar'][ info[#info] ] = value; UF:CreateAndUpdateUF('target') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},	
				matchsize = {
					order = 2,
					type = 'execute',
					name = L['Match Frame Width'],
					func = function() E.db.unitframe.units['target']['castbar']['width'] = E.db.unitframe.units['target']['width']; UF:CreateAndUpdateUF('target') end,
				},			
				forceshow = {
					order = 3,
					name = SHOW..' / '..HIDE,
					func = function() 
						local castbar = ElvUF_Target.Castbar
						if not castbar.oldHide then
							castbar.oldHide = castbar.Hide
							castbar.Hide = castbar.Show
							castbar:Show()
						else
							castbar.Hide = castbar.oldHide
							castbar.oldHide = nil
							castbar:Hide()						
						end
					end,
					type = 'execute',
				},
				width = {
					order = 4,
					name = L['Width'],
					type = 'range',
					min = 50, max = 600, step = 1,
				},
				height = {
					order = 5,
					name = L['Height'],
					type = 'range',
					min = 10, max = 85, step = 1,
				},		
				icon = {
					order = 6,
					name = L['Icon'],
					type = 'toggle',
				},
				xOffset = {
					order = 7,
					name = L['X Offset'],
					type = 'range',
					min = -E.screenwidth, max = E.screenwidth, step = 1,
				},
				yOffset = {
					order = 8,
					name = L['Y Offset'],
					type = 'range',
					min = -E.screenheight, max = E.screenheight, step = 1,
				},				
				color = {
					order = 9,
					type = 'color',
					name = L['Color'],
					get = function(info)
						local t = E.db.unitframe.units['target']['castbar'][ info[#info] ]
						return t.r, t.g, t.b, t.a
					end,
					set = function(info, r, g, b)
						E.db.general[ info[#info] ] = {}
						local t = E.db.unitframe.units['target']['castbar'][ info[#info] ]
						t.r, t.g, t.b = r, g, b
						UF:CreateAndUpdateUF('target')
					end,													
				},
				interruptcolor = {
					order = 10,
					type = 'color',
					name = L['Interrupt Color'],
					get = function(info)
						local t = E.db.unitframe.units['target']['castbar'][ info[#info] ]
						return t.r, t.g, t.b, t.a
					end,
					set = function(info, r, g, b)
						E.db.general[ info[#info] ] = {}
						local t = E.db.unitframe.units['target']['castbar'][ info[#info] ]
						t.r, t.g, t.b = r, g, b
						UF:CreateAndUpdateUF('target')
					end,					
				},
				format = {
					order = 11,
					type = 'select',
					name = L['Format'],
					values = {
						['CURRENTMAX'] = L['Current / Max'],
						['CURRENT'] = L['Current'],
						['REMAINING'] = L['Remaining'],
					},
				},		
				spark = {
					order = 12,
					type = 'toggle',
					name = L['Spark'],
					desc = L['Display a spark texture at the end of the castbar statusbar to help show the differance between castbar and backdrop.'],
				},				
			},
		},
		combobar = {
			order = 800,
			type = 'group',
			name = L['Combobar'],
			get = function(info) return E.db.unitframe.units['target']['combobar'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['target']['combobar'][ info[#info] ] = value; UF:CreateAndUpdateUF('target') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				height = {
					type = 'range',
					order = 2,
					name = L['Height'],
					min = 5, max = 15, step = 1,
				},	
				fill = {
					type = 'select',
					order = 3,
					name = L['Fill'],
					values = fillValues,
				},				
			},
		},		
	},
}

--TargetTarget
E.Options.args.unitframe.args.targettarget = {
	name = L['TargetTarget Frame'],
	type = 'group',
	order = 500,
	childGroups = "select",
	get = function(info) return E.db.unitframe.units['targettarget'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['targettarget'][ info[#info] ] = value; UF:CreateAndUpdateUF('targettarget') end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		copyFrom = {
			type = 'select',
			order = 2,
			name = L['Copy From'],
			desc = L['Select a unit to copy settings from.'],
			values = UF['handledunits'],
			set = function(info, value) UF:MergeUnitSettings(value, 'targettarget'); end,
		},
		resetSettings = {
			type = 'execute',
			order = 3,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('targettarget') end,
		},		
		width = {
			order = 4,
			name = L['Width'],
			type = 'range',
			min = 50, max = 500, step = 1,
		},
		height = {
			order = 5,
			name = L['Height'],
			type = 'range',
			min = 10, max = 250, step = 1,
		},	
		health = {
			order = 6,
			type = 'group',
			name = L['Health'],
			get = function(info) return E.db.unitframe.units['targettarget']['health'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['targettarget']['health'][ info[#info] ] = value; UF:CreateAndUpdateUF('targettarget') end,
			args = {
				text = {
					type = 'toggle',
					order = 1,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 2,
					name = L['Text Format'],
					values = textFormats,
				},
				position = {
					type = 'select',
					order = 3,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		power = {
			order = 7,
			type = 'group',
			name = L['Power'],
			get = function(info) return E.db.unitframe.units['targettarget']['power'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['targettarget']['power'][ info[#info] ] = value; UF:CreateAndUpdateUF('targettarget') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},			
				text = {
					type = 'toggle',
					order = 2,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 3,
					name = L['Text Format'],
					values = textFormats,
				},
				width = {
					type = 'select',
					order = 4,
					name = L['Width'],
					values = fillValues,
				},
				height = {
					type = 'range',
					name = L['Height'],
					order = 5,
					min = 2, max = 50, step = 1,
				},
				offset = {
					type = 'range',
					name = L['Offset'],
					desc = L['Offset of the powerbar to the healthbar, set to 0 to disable.'],
					order = 6,
					min = 0, max = 20, step = 1,
				},
				hideonnpc = {
					type = 'toggle',
					order = 7,
					name = L['Text Toggle On NPC'],
					desc = L['Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point.'],
				},
				position = {
					type = 'select',
					order = 8,
					name = L['Position'],
					values = positionValues,
				},						
			},
		},	
		name = {
			order = 9,
			type = 'group',
			name = L['Name'],
			get = function(info) return E.db.unitframe.units['targettarget']['name'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['targettarget']['name'][ info[#info] ] = value; UF:CreateAndUpdateUF('targettarget') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		buffs = {
			order = 11,
			type = 'group',
			name = L['Buffs'],
			get = function(info) return E.db.unitframe.units['targettarget']['buffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['targettarget']['buffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('targettarget') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['DEBUFFS'] = L['Debuffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},				
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},		
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},	
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		debuffs = {
			order = 12,
			type = 'group',
			name = L['Debuffs'],
			get = function(info) return E.db.unitframe.units['targettarget']['debuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['targettarget']['debuffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('targettarget'); end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['BUFFS'] = L['Buffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},	
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
	},
}

--Focus
E.Options.args.unitframe.args.focus = {
	name = L['Focus Frame'],
	type = 'group',
	order = 600,
	childGroups = "select",
	get = function(info) return E.db.unitframe.units['focus'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['focus'][ info[#info] ] = value; UF:CreateAndUpdateUF('focus') end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		copyFrom = {
			type = 'select',
			order = 2,
			name = L['Copy From'],
			desc = L['Select a unit to copy settings from.'],
			values = UF['handledunits'],
			set = function(info, value) UF:MergeUnitSettings(value, 'focus'); end,
		},
		resetSettings = {
			type = 'execute',
			order = 3,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('focus') end,
		},		
		width = {
			order = 4,
			name = L['Width'],
			type = 'range',
			min = 50, max = 500, step = 1,
		},
		height = {
			order = 5,
			name = L['Height'],
			type = 'range',
			min = 10, max = 250, step = 1,
		},	
		healPrediction = {
			order = 6,
			name = L['Heal Prediction'],
			desc = L['Show a incomming heal prediction bar on the unitframe. Also display a slightly different colored bar for incoming overheals.'],
			type = 'toggle',
		},
		health = {
			order = 100,
			type = 'group',
			name = L['Health'],
			get = function(info) return E.db.unitframe.units['focus']['health'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['focus']['health'][ info[#info] ] = value; UF:CreateAndUpdateUF('focus') end,
			args = {
				text = {
					type = 'toggle',
					order = 1,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 2,
					name = L['Text Format'],
					values = textFormats,
				},
				position = {
					type = 'select',
					order = 3,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		power = {
			order = 200,
			type = 'group',
			name = L['Power'],
			get = function(info) return E.db.unitframe.units['focus']['power'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['focus']['power'][ info[#info] ] = value; UF:CreateAndUpdateUF('focus') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},			
				text = {
					type = 'toggle',
					order = 2,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 3,
					name = L['Text Format'],
					values = textFormats,
				},
				width = {
					type = 'select',
					order = 4,
					name = L['Width'],
					values = fillValues,
				},
				height = {
					type = 'range',
					name = L['Height'],
					order = 5,
					min = 2, max = 50, step = 1,
				},
				offset = {
					type = 'range',
					name = L['Offset'],
					desc = L['Offset of the powerbar to the healthbar, set to 0 to disable.'],
					order = 6,
					min = 0, max = 20, step = 1,
				},
				hideonnpc = {
					type = 'toggle',
					order = 7,
					name = L['Text Toggle On NPC'],
					desc = L['Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point.'],
				},
				position = {
					type = 'select',
					order = 8,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},	
		name = {
			order = 300,
			type = 'group',
			name = L['Name'],
			get = function(info) return E.db.unitframe.units['focus']['name'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['focus']['name'][ info[#info] ] = value; UF:CreateAndUpdateUF('focus') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		buffs = {
			order = 400,
			type = 'group',
			name = L['Buffs'],
			get = function(info) return E.db.unitframe.units['focus']['buffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['focus']['buffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('focus') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['DEBUFFS'] = L['Debuffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},				
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},		
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},	
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		debuffs = {
			order = 500,
			type = 'group',
			name = L['Debuffs'],
			get = function(info) return E.db.unitframe.units['focus']['debuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['focus']['debuffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('focus') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['BUFFS'] = L['Buffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},	
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		castbar = {
			order = 600,
			type = 'group',
			name = L['Castbar'],
			get = function(info) return E.db.unitframe.units['focus']['castbar'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['focus']['castbar'][ info[#info] ] = value; UF:CreateAndUpdateUF('focus') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},	
				matchsize = {
					order = 2,
					type = 'execute',
					name = L['Match Frame Width'],
					func = function() E.db.unitframe.units['focus']['castbar']['width'] = E.db.unitframe.units['focus']['width']; UF:CreateAndUpdateUF('focus') end,
				},			
				forceshow = {
					order = 3,
					name = SHOW..' / '..HIDE,
					func = function() 
						local castbar = ElvUF_Focus.Castbar
						if not castbar.oldHide then
							castbar.oldHide = castbar.Hide
							castbar.Hide = castbar.Show
							castbar:Show()
						else
							castbar.Hide = castbar.oldHide
							castbar.oldHide = nil
							castbar:Hide()						
						end
					end,
					type = 'execute',
				},
				width = {
					order = 4,
					name = L['Width'],
					type = 'range',
					min = 50, max = 600, step = 1,
				},
				height = {
					order = 5,
					name = L['Height'],
					type = 'range',
					min = 10, max = 85, step = 1,
				},		
				icon = {
					order = 6,
					name = L['Icon'],
					type = 'toggle',
				},
				xOffset = {
					order = 7,
					name = L['X Offset'],
					type = 'range',
					min = -E.screenwidth, max = E.screenwidth, step = 1,
				},
				yOffset = {
					order = 8,
					name = L['Y Offset'],
					type = 'range',
					min = -E.screenheight, max = E.screenheight, step = 1,
				},				
				color = {
					order = 9,
					type = 'color',
					name = L['Color'],
					get = function(info)
						local t = E.db.unitframe.units['focus']['castbar'][ info[#info] ]
						return t.r, t.g, t.b, t.a
					end,
					set = function(info, r, g, b)
						E.db.general[ info[#info] ] = {}
						local t = E.db.unitframe.units['focus']['castbar'][ info[#info] ]
						t.r, t.g, t.b = r, g, b
						UF:CreateAndUpdateUF('focus')
					end,													
				},
				interruptcolor = {
					order = 10,
					type = 'color',
					name = L['Interrupt Color'],
					get = function(info)
						local t = E.db.unitframe.units['focus']['castbar'][ info[#info] ]
						return t.r, t.g, t.b, t.a
					end,
					set = function(info, r, g, b)
						E.db.general[ info[#info] ] = {}
						local t = E.db.unitframe.units['focus']['castbar'][ info[#info] ]
						t.r, t.g, t.b = r, g, b
						UF:CreateAndUpdateUF('focus')
					end,					
				},
				format = {
					order = 11,
					type = 'select',
					name = L['Format'],
					values = {
						['CURRENTMAX'] = L['Current / Max'],
						['CURRENT'] = L['Current'],
						['REMAINING'] = L['Remaining'],
					},
				},	
				spark = {
					order = 12,
					type = 'toggle',
					name = L['Spark'],
					desc = L['Display a spark texture at the end of the castbar statusbar to help show the differance between castbar and backdrop.'],
				},				
			},
		},		
	},
}

--Focus Target
E.Options.args.unitframe.args.focustarget = {
	name = L['FocusTarget Frame'],
	type = 'group',
	order = 700,
	childGroups = "select",
	get = function(info) return E.db.unitframe.units['focustarget'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['focustarget'][ info[#info] ] = value; UF:CreateAndUpdateUF('focustarget') end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		copyFrom = {
			type = 'select',
			order = 2,
			name = L['Copy From'],
			desc = L['Select a unit to copy settings from.'],
			values = UF['handledunits'],
			set = function(info, value) UF:MergeUnitSettings(value, 'focustarget'); end,
		},
		resetSettings = {
			type = 'execute',
			order = 3,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('focustarget') end,
		},		
		width = {
			order = 4,
			name = L['Width'],
			type = 'range',
			min = 50, max = 500, step = 1,
		},
		height = {
			order = 5,
			name = L['Height'],
			type = 'range',
			min = 10, max = 250, step = 1,
		},	
		health = {
			order = 6,
			type = 'group',
			name = L['Health'],
			get = function(info) return E.db.unitframe.units['focustarget']['health'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['focustarget']['health'][ info[#info] ] = value; UF:CreateAndUpdateUF('focustarget') end,
			args = {
				text = {
					type = 'toggle',
					order = 1,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 2,
					name = L['Text Format'],
					values = textFormats,
				},
				position = {
					type = 'select',
					order = 3,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		power = {
			order = 7,
			type = 'group',
			name = L['Power'],
			get = function(info) return E.db.unitframe.units['focustarget']['power'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['focustarget']['power'][ info[#info] ] = value; UF:CreateAndUpdateUF('focustarget') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},			
				text = {
					type = 'toggle',
					order = 2,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 3,
					name = L['Text Format'],
					values = textFormats,
				},
				width = {
					type = 'select',
					order = 4,
					name = L['Width'],
					values = fillValues,
				},
				height = {
					type = 'range',
					name = L['Height'],
					order = 5,
					min = 2, max = 50, step = 1,
				},
				offset = {
					type = 'range',
					name = L['Offset'],
					desc = L['Offset of the powerbar to the healthbar, set to 0 to disable.'],
					order = 6,
					min = 0, max = 20, step = 1,
				},
				hideonnpc = {
					type = 'toggle',
					order = 7,
					name = L['Text Toggle On NPC'],
					desc = L['Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point.'],
				},
				position = {
					type = 'select',
					order = 8,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},	
		name = {
			order = 9,
			type = 'group',
			name = L['Name'],
			get = function(info) return E.db.unitframe.units['focustarget']['name'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['focustarget']['name'][ info[#info] ] = value; UF:CreateAndUpdateUF('focustarget') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		buffs = {
			order = 11,
			type = 'group',
			name = L['Buffs'],
			get = function(info) return E.db.unitframe.units['focustarget']['buffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['focustarget']['buffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('focustarget') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['DEBUFFS'] = L['Debuffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},				
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},		
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},	
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		debuffs = {
			order = 12,
			type = 'group',
			name = L['Debuffs'],
			get = function(info) return E.db.unitframe.units['focustarget']['debuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['focustarget']['debuffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('focustarget') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},	
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['BUFFS'] = L['Buffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},	
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
	},
}

--Pet
E.Options.args.unitframe.args.pet = {
	name = L['Pet Frame'],
	type = 'group',
	order = 800,
	childGroups = "select",
	get = function(info) return E.db.unitframe.units['pet'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['pet'][ info[#info] ] = value; UF:CreateAndUpdateUF('pet') end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		copyFrom = {
			type = 'select',
			order = 2,
			name = L['Copy From'],
			desc = L['Select a unit to copy settings from.'],
			values = UF['handledunits'],
			set = function(info, value) UF:MergeUnitSettings(value, 'pet'); end,
		},
		resetSettings = {
			type = 'execute',
			order = 3,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('pet') end,
		},		
		width = {
			order = 4,
			name = L['Width'],
			type = 'range',
			min = 50, max = 500, step = 1,
		},
		height = {
			order = 5,
			name = L['Height'],
			type = 'range',
			min = 10, max = 250, step = 1,
		},	
		healPrediction = {
			order = 6,
			name = L['Heal Prediction'],
			desc = L['Show a incomming heal prediction bar on the unitframe. Also display a slightly different colored bar for incoming overheals.'],
			type = 'toggle',
		},		
		health = {
			order = 100,
			type = 'group',
			name = L['Health'],
			get = function(info) return E.db.unitframe.units['pet']['health'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['pet']['health'][ info[#info] ] = value; UF:CreateAndUpdateUF('pet') end,
			args = {
				text = {
					type = 'toggle',
					order = 1,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 2,
					name = L['Text Format'],
					values = textFormats,
				},
				position = {
					type = 'select',
					order = 3,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		power = {
			order = 200,
			type = 'group',
			name = L['Power'],
			get = function(info) return E.db.unitframe.units['pet']['power'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['pet']['power'][ info[#info] ] = value; UF:CreateAndUpdateUF('pet') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},			
				text = {
					type = 'toggle',
					order = 2,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 3,
					name = L['Text Format'],
					values = textFormats,
				},
				width = {
					type = 'select',
					order = 4,
					name = L['Width'],
					values = fillValues,
				},
				height = {
					type = 'range',
					name = L['Height'],
					order = 5,
					min = 2, max = 50, step = 1,
				},
				offset = {
					type = 'range',
					name = L['Offset'],
					desc = L['Offset of the powerbar to the healthbar, set to 0 to disable.'],
					order = 6,
					min = 0, max = 20, step = 1,
				},
				hideonnpc = {
					type = 'toggle',
					order = 7,
					name = L['Text Toggle On NPC'],
					desc = L['Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point.'],
				},
				position = {
					type = 'select',
					order = 8,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},	
		name = {
			order = 300,
			type = 'group',
			name = L['Name'],
			get = function(info) return E.db.unitframe.units['pet']['name'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['pet']['name'][ info[#info] ] = value; UF:CreateAndUpdateUF('pet') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		buffs = {
			order = 400,
			type = 'group',
			name = L['Buffs'],
			get = function(info) return E.db.unitframe.units['pet']['buffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['pet']['buffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('pet') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['DEBUFFS'] = L['Debuffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},				
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},		
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},	
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		debuffs = {
			order = 500,
			type = 'group',
			name = L['Debuffs'],
			get = function(info) return E.db.unitframe.units['pet']['debuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['pet']['debuffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('pet') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['BUFFS'] = L['Buffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},	
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
	},
}

--Pet Target
E.Options.args.unitframe.args.pettarget = {
	name = L['PetTarget Frame'],
	type = 'group',
	order = 900,
	childGroups = "select",
	get = function(info) return E.db.unitframe.units['pettarget'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['pettarget'][ info[#info] ] = value; UF:CreateAndUpdateUF('pettarget') end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		copyFrom = {
			type = 'select',
			order = 2,
			name = L['Copy From'],
			desc = L['Select a unit to copy settings from.'],
			values = UF['handledunits'],
			set = function(info, value) UF:MergeUnitSettings(value, 'pettarget'); end,
		},
		resetSettings = {
			type = 'execute',
			order = 3,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('pettarget') end,
		},		
		width = {
			order = 4,
			name = L['Width'],
			type = 'range',
			min = 50, max = 500, step = 1,
		},
		height = {
			order = 5,
			name = L['Height'],
			type = 'range',
			min = 10, max = 250, step = 1,
		},	
		health = {
			order = 6,
			type = 'group',
			name = L['Health'],
			get = function(info) return E.db.unitframe.units['pettarget']['health'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['pettarget']['health'][ info[#info] ] = value; UF:CreateAndUpdateUF('pettarget') end,
			args = {
				text = {
					type = 'toggle',
					order = 1,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 2,
					name = L['Text Format'],
					values = textFormats,
				},
				position = {
					type = 'select',
					order = 3,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		power = {
			order = 7,
			type = 'group',
			name = L['Power'],
			get = function(info) return E.db.unitframe.units['pettarget']['power'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['pettarget']['power'][ info[#info] ] = value; UF:CreateAndUpdateUF('pettarget') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},			
				text = {
					type = 'toggle',
					order = 2,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 3,
					name = L['Text Format'],
					values = textFormats,
				},
				width = {
					type = 'select',
					order = 4,
					name = L['Width'],
					values = fillValues,
				},
				height = {
					type = 'range',
					name = L['Height'],
					order = 5,
					min = 2, max = 50, step = 1,
				},
				offset = {
					type = 'range',
					name = L['Offset'],
					desc = L['Offset of the powerbar to the healthbar, set to 0 to disable.'],
					order = 6,
					min = 0, max = 20, step = 1,
				},
				hideonnpc = {
					type = 'toggle',
					order = 7,
					name = L['Text Toggle On NPC'],
					desc = L['Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point.'],
				},
				position = {
					type = 'select',
					order = 8,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},	
		name = {
			order = 9,
			type = 'group',
			name = L['Name'],
			get = function(info) return E.db.unitframe.units['pettarget']['name'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['pettarget']['name'][ info[#info] ] = value; UF:CreateAndUpdateUF('pettarget') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		buffs = {
			order = 11,
			type = 'group',
			name = L['Buffs'],
			get = function(info) return E.db.unitframe.units['pettarget']['buffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['pettarget']['buffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('pettarget') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['DEBUFFS'] = L['Debuffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},				
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},		
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},	
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		debuffs = {
			order = 12,
			type = 'group',
			name = L['Debuffs'],
			get = function(info) return E.db.unitframe.units['pettarget']['debuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['pettarget']['debuffs'][ info[#info] ] = value; UF:CreateAndUpdateUF('pettarget') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['BUFFS'] = L['Buffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},	
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
	},
}

--Boss Frames
E.Options.args.unitframe.args.boss = {
	name = L['Boss Frames'],
	type = 'group',
	order = 1000,
	childGroups = "select",
	get = function(info) return E.db.unitframe.units['boss'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['boss'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('boss', MAX_BOSS_FRAMES) end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		copyFrom = {
			type = 'select',
			order = 2,
			name = L['Copy From'],
			desc = L['Select a unit to copy settings from.'],
			values = {
				['boss'] = 'boss',
				['arena'] = 'arena',
			},
			set = function(info, value) UF:MergeUnitSettings(value, 'boss'); end,
		},
		resetSettings = {
			type = 'execute',
			order = 3,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('boss') end,
		},		
		width = {
			order = 4,
			name = L['Width'],
			type = 'range',
			min = 50, max = 500, step = 1,
			set = function(info, value) 
				if E.db.unitframe.units['boss'].castbar.width == E.db.unitframe.units['boss'][ info[#info] ] then
					E.db.unitframe.units['boss'].castbar.width = value;
				end
				
				E.db.unitframe.units['boss'][ info[#info] ] = value; 
				UF:CreateAndUpdateUFGroup('boss', MAX_BOSS_FRAMES);
			end,			
		},
		height = {
			order = 5,
			name = L['Height'],
			type = 'range',
			min = 10, max = 250, step = 1,
		},	
		growthDirection = {
			order = 6,
			name = L['Growth Direction'],
			type = 'select',
			values = {
				['UP'] = L['Up'],
				['DOWN'] = L['Down'],
			},
		},
		health = {
			order = 7,
			type = 'group',
			name = L['Health'],
			get = function(info) return E.db.unitframe.units['boss']['health'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['boss']['health'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('boss', MAX_BOSS_FRAMES) end,
			args = {
				text = {
					type = 'toggle',
					order = 1,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 2,
					name = L['Text Format'],
					values = textFormats,
				},
				position = {
					type = 'select',
					order = 3,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		power = {
			order = 8,
			type = 'group',
			name = L['Power'],
			get = function(info) return E.db.unitframe.units['boss']['power'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['boss']['power'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('boss', MAX_BOSS_FRAMES) end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},			
				text = {
					type = 'toggle',
					order = 2,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 3,
					name = L['Text Format'],
					values = textFormats,
				},
				width = {
					type = 'select',
					order = 4,
					name = L['Width'],
					values = fillValues,
				},
				height = {
					type = 'range',
					name = L['Height'],
					order = 5,
					min = 2, max = 50, step = 1,
				},
				offset = {
					type = 'range',
					name = L['Offset'],
					desc = L['Offset of the powerbar to the healthbar, set to 0 to disable.'],
					order = 6,
					min = 0, max = 20, step = 1,
				},
				hideonnpc = {
					type = 'toggle',
					order = 7,
					name = L['Text Toggle On NPC'],
					desc = L['Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point.'],
				},
				position = {
					type = 'select',
					order = 8,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},	
		name = {
			order = 9,
			type = 'group',
			name = L['Name'],
			get = function(info) return E.db.unitframe.units['boss']['name'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['boss']['name'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('boss', MAX_BOSS_FRAMES) end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		portrait = {
			order = 10,
			type = 'group',
			name = L['Portrait'],
			get = function(info) return E.db.unitframe.units['boss']['portrait'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['boss']['portrait'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('boss', MAX_BOSS_FRAMES) end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				width = {
					type = 'range',
					order = 2,
					name = L['Width'],
					min = 15, max = 150, step = 1,
				},
				overlay = {
					type = 'toggle',
					name = L['Overlay'],
					desc = L['Overlay the healthbar'],
					order = 3,
				},
				camDistanceScale = {
					type = 'range',
					name = L['Camera Distance Scale'],
					desc = L['How far away the portrait is from the camera.'],
					order = 4,
					min = 0.01, max = 4, step = 0.01,
				},				
			},
		},	
		buffs = {
			order = 11,
			type = 'group',
			name = L['Buffs'],
			get = function(info) return E.db.unitframe.units['boss']['buffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['boss']['buffs'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('boss', MAX_BOSS_FRAMES) end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['DEBUFFS'] = L['Debuffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},				
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},		
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},	
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		debuffs = {
			order = 12,
			type = 'group',
			name = L['Debuffs'],
			get = function(info) return E.db.unitframe.units['boss']['debuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['boss']['debuffs'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('boss', MAX_BOSS_FRAMES) end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['BUFFS'] = L['Buffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},	
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		castbar = {
			order = 13,
			type = 'group',
			name = L['Castbar'],
			get = function(info) return E.db.unitframe.units['boss']['castbar'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['boss']['castbar'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('boss', MAX_BOSS_FRAMES) end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},	
				matchsize = {
					order = 2,
					type = 'execute',
					name = L['Match Frame Width'],
					func = function() E.db.unitframe.units['boss']['castbar']['width'] = E.db.unitframe.units['boss']['width']; UF:CreateAndUpdateUFGroup('boss', MAX_BOSS_FRAMES) end,
				},				
				width = {
					order = 3,
					name = L['Width'],
					type = 'range',
					min = 50, max = 600, step = 1,
				},
				height = {
					order = 4,
					name = L['Height'],
					type = 'range',
					min = 10, max = 85, step = 1,
				},		
				icon = {
					order = 5,
					name = L['Icon'],
					type = 'toggle',
				},
				color = {
					order = 7,
					type = 'color',
					name = L['Color'],
					get = function(info)
						local t = E.db.unitframe.units['boss']['castbar'][ info[#info] ]
						return t.r, t.g, t.b, t.a
					end,
					set = function(info, r, g, b)
						E.db.general[ info[#info] ] = {}
						local t = E.db.unitframe.units['boss']['castbar'][ info[#info] ]
						t.r, t.g, t.b = r, g, b
						UF:CreateAndUpdateUFGroup('boss', MAX_BOSS_FRAMES)
					end,													
				},
				interruptcolor = {
					order = 8,
					type = 'color',
					name = L['Interrupt Color'],
					get = function(info)
						local t = E.db.unitframe.units['boss']['castbar'][ info[#info] ]
						return t.r, t.g, t.b, t.a
					end,
					set = function(info, r, g, b)
						E.db.general[ info[#info] ] = {}
						local t = E.db.unitframe.units['boss']['castbar'][ info[#info] ]
						t.r, t.g, t.b = r, g, b
						UF:CreateAndUpdateUFGroup('boss', MAX_BOSS_FRAMES)
					end,					
				},
				format = {
					order = 9,
					type = 'select',
					name = L['Format'],
					values = {
						['CURRENTMAX'] = L['Current / Max'],
						['CURRENT'] = L['Current'],
						['REMAINING'] = L['Remaining'],
					},
				},		
				spark = {
					order = 10,
					type = 'toggle',
					name = L['Spark'],
					desc = L['Display a spark texture at the end of the castbar statusbar to help show the differance between castbar and backdrop.'],
				},				
			},
		},	
	},
}

--Arena Frames
E.Options.args.unitframe.args.arena = {
	name = L['Arena Frames'],
	type = 'group',
	order = 1000,
	childGroups = "select",
	get = function(info) return E.db.unitframe.units['arena'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['arena'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('arena', 5) end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		copyFrom = {
			type = 'select',
			order = 2,
			name = L['Copy From'],
			desc = L['Select a unit to copy settings from.'],
			values = {
				['boss'] = 'boss',
				['arena'] = 'arena',
			},
			set = function(info, value) UF:MergeUnitSettings(value, 'arena'); end,
		},
		resetSettings = {
			type = 'execute',
			order = 3,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('arena') end,
		},		
		width = {
			order = 4,
			name = L['Width'],
			type = 'range',
			min = 50, max = 500, step = 1,
			set = function(info, value) 
				if E.db.unitframe.units['arena'].castbar.width == E.db.unitframe.units['arena'][ info[#info] ] then
					E.db.unitframe.units['arena'].castbar.width = value;
				end
				
				E.db.unitframe.units['arena'][ info[#info] ] = value; 
				UF:CreateAndUpdateUFGroup('arena', 5);
			end,			
		},
		height = {
			order = 5,
			name = L['Height'],
			type = 'range',
			min = 10, max = 250, step = 1,
		},	
		growthDirection = {
			order = 6,
			name = L['Growth Direction'],
			type = 'select',
			values = {
				['UP'] = L['Up'],
				['DOWN'] = L['Down'],
			},
		},
		health = {
			order = 7,
			type = 'group',
			name = L['Health'],
			get = function(info) return E.db.unitframe.units['arena']['health'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['arena']['health'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('arena', 5) end,
			args = {
				text = {
					type = 'toggle',
					order = 1,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 2,
					name = L['Text Format'],
					values = textFormats,
				},
				position = {
					type = 'select',
					order = 3,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		power = {
			order = 8,
			type = 'group',
			name = L['Power'],
			get = function(info) return E.db.unitframe.units['arena']['power'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['arena']['power'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('arena', 5) end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},			
				text = {
					type = 'toggle',
					order = 2,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 3,
					name = L['Text Format'],
					values = textFormats,
				},
				width = {
					type = 'select',
					order = 4,
					name = L['Width'],
					values = fillValues,
				},
				height = {
					type = 'range',
					name = L['Height'],
					order = 5,
					min = 2, max = 50, step = 1,
				},
				offset = {
					type = 'range',
					name = L['Offset'],
					desc = L['Offset of the powerbar to the healthbar, set to 0 to disable.'],
					order = 6,
					min = 0, max = 20, step = 1,
				},
				hideonnpc = {
					type = 'toggle',
					order = 7,
					name = L['Text Toggle On NPC'],
					desc = L['Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point.'],
				},
				position = {
					type = 'select',
					order = 8,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},	
		name = {
			order = 9,
			type = 'group',
			name = L['Name'],
			get = function(info) return E.db.unitframe.units['arena']['name'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['arena']['name'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('arena', 5) end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},
		buffs = {
			order = 11,
			type = 'group',
			name = L['Buffs'],
			get = function(info) return E.db.unitframe.units['arena']['buffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['arena']['buffs'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('arena', 5) end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['DEBUFFS'] = L['Debuffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},				
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},		
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},	
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		debuffs = {
			order = 12,
			type = 'group',
			name = L['Debuffs'],
			get = function(info) return E.db.unitframe.units['arena']['debuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['arena']['debuffs'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('arena', 5) end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['BUFFS'] = L['Buffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},	
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		castbar = {
			order = 13,
			type = 'group',
			name = L['Castbar'],
			get = function(info) return E.db.unitframe.units['arena']['castbar'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['arena']['castbar'][ info[#info] ] = value; UF:CreateAndUpdateUFGroup('arena', 5) end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},	
				matchsize = {
					order = 2,
					type = 'execute',
					name = L['Match Frame Width'],
					func = function() E.db.unitframe.units['arena']['castbar']['width'] = E.db.unitframe.units['arena']['width']; UF:CreateAndUpdateUFGroup('arena', 5) end,
				},				
				width = {
					order = 3,
					name = L['Width'],
					type = 'range',
					min = 50, max = 600, step = 1,
				},
				height = {
					order = 4,
					name = L['Height'],
					type = 'range',
					min = 10, max = 85, step = 1,
				},		
				icon = {
					order = 5,
					name = L['Icon'],
					type = 'toggle',
				},
				color = {
					order = 7,
					type = 'color',
					name = L['Color'],
					get = function(info)
						local t = E.db.unitframe.units['arena']['castbar'][ info[#info] ]
						return t.r, t.g, t.b, t.a
					end,
					set = function(info, r, g, b)
						E.db.general[ info[#info] ] = {}
						local t = E.db.unitframe.units['arena']['castbar'][ info[#info] ]
						t.r, t.g, t.b = r, g, b
						UF:CreateAndUpdateUFGroup('arena', 5)
					end,													
				},
				interruptcolor = {
					order = 8,
					type = 'color',
					name = L['Interrupt Color'],
					get = function(info)
						local t = E.db.unitframe.units['arena']['castbar'][ info[#info] ]
						return t.r, t.g, t.b, t.a
					end,
					set = function(info, r, g, b)
						E.db.general[ info[#info] ] = {}
						local t = E.db.unitframe.units['arena']['castbar'][ info[#info] ]
						t.r, t.g, t.b = r, g, b
						UF:CreateAndUpdateUFGroup('arena', 5)
					end,					
				},
				format = {
					order = 9,
					type = 'select',
					name = L['Format'],
					values = {
						['CURRENTMAX'] = L['Current / Max'],
						['CURRENT'] = L['Current'],
						['REMAINING'] = L['Remaining'],
					},
				},	
				spark = {
					order = 10,
					type = 'toggle',
					name = L['Spark'],
					desc = L['Display a spark texture at the end of the castbar statusbar to help show the differance between castbar and backdrop.'],
				},				
			},
		},	
	},
}

local groupPoints = {
	['TOP'] = 'TOP',
	['BOTTOM'] = 'BOTTOM',
	['LEFT'] = 'LEFT',
	['RIGHT'] = 'RIGHT',
}

--Party Frames
E.Options.args.unitframe.args.party = {
	name = L['Party Frames'],
	type = 'group',
	order = 1100,
	childGroups = "select",
	get = function(info) return E.db.unitframe.units['party'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['party'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('party') end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		resetSettings = {
			type = 'execute',
			order = 2,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('party') end,
		},		
		general = {
			order = 5,
			type = 'group',
			name = L['General'],
			args = {
				width = {
					order = 2,
					name = L['Width'],
					type = 'range',
					min = 50, max = 500, step = 1,
				},			
				height = {
					order = 3,
					name = L['Height'],
					type = 'range',
					min = 10, max = 250, step = 1,
				},	
				point = {
					order = 4,
					type = 'select',
					name = L['Group Point'],
					desc = L['What each frame should attach itself to, example setting it to TOP every unit will attach its top to the last point bottom.'],
					values = groupPoints,
					set = function(info, value) E.db.unitframe.units['party'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('party'); end,
				},
				columnAnchorPoint = {
					order = 5,
					type = 'select',
					name = L['Column Point'],
					desc = L['The anchor point for each new column. A value of LEFT will cause the columns to grow to the right.'],
					values = groupPoints,	
					set = function(info, value) E.db.unitframe.units['party'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('party'); end,
				},
				maxColumns = {
					order = 6,
					type = 'range',
					name = L['Max Columns'],
					desc = L['The maximum number of columns that the header will create.'],
					min = 1, max = 40, step = 1,
				},
				unitsPerColumn = {
					order = 7,
					type = 'range',
					name = L['Units Per Column'],
					desc = L['The maximum number of units that will be displayed in a single column.'],
					min = 1, max = 40, step = 1,
				},
				columnSpacing = {
					order = 8,
					type = 'range',
					name = L['Column Spacing'],
					desc = L['The amount of space (in pixels) between the columns.'],
					min = 3, max = 10, step = 1,
				},		
				xOffset = {
					order = 9,
					type = 'range',
					name = L['xOffset'],
					desc = L['An X offset (in pixels) to be used when anchoring new frames.'],
					min = -15, max = 15, step = 1,		
				},
				yOffset = {
					order = 10,
					type = 'range',
					name = L['yOffset'],
					desc = L['An Y offset (in pixels) to be used when anchoring new frames.'],
					min = -15, max = 15, step = 1,		
				},		
				showParty = {
					order = 11,
					type = 'toggle',
					name = L['Show Party'],
					desc = L['When true, the group header is shown when the player is in a party.'],
				},
				showRaid = {
					order = 12,
					type = 'toggle',
					name = L['Show Raid'],
					desc = L['When true, the group header is shown when the player is in a raid.'],
				},	
				showSolo = {
					order = 13,
					type = 'toggle',
					name = L['Show Solo'],
					desc = L['When true, the header is shown when the player is not in any group.'],		
				},
				showPlayer = {
					order = 14,
					type = 'toggle',
					name = L['Display Player'],
					desc = L['When true, the header includes the player when not in a raid.'],			
				},
				healPrediction = {
					order = 15,
					name = L['Heal Prediction'],
					desc = L['Show a incomming heal prediction bar on the unitframe. Also display a slightly different colored bar for incoming overheals.'],
					type = 'toggle',
				},		
				groupBy = {
					order = 16,
					name = L['Group By'],
					desc = L['Set the order that the group will sort.'],
					type = 'select',		
					values = {
						['CLASS'] = CLASS,
						['TANK'] = L["Tanks First"],
						['GROUP'] = GROUP,
					},
				},
				visibility = {
					order = 200,
					type = 'input',
					name = L['Visibility'],
					desc = L['The following macro must be true in order for the group to be shown, in addition to any filter that may already be set.'],
					width = 'full',
				},				
			},
		},
		health = {
			order = 100,
			type = 'group',
			name = L['Health'],
			get = function(info) return E.db.unitframe.units['party']['health'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['party']['health'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('party'); end,
			args = {
				text = {
					type = 'toggle',
					order = 1,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 2,
					name = L['Text Format'],
					values = textFormats,
				},
				position = {
					type = 'select',
					order = 3,
					name = L['Position'],
					values = positionValues,
				},	
				frequentUpdates = {
					type = 'toggle',
					order = 4,
					name = L['Frequent Updates'],
					desc = L['Rapidly update the health, uses more memory and cpu. Only recommended for healing.'],
				},
				orientation = {
					type = 'select',
					order = 5,
					name = L['Orientation'],
					desc = L['Direction the health bar moves when gaining/losing health.'],
					values = {
						['HORIZONTAL'] = L['Horizontal'],
						['VERTICAL'] = L['Vertical'],
					},
				},		
			},
		},
		power = {
			order = 200,
			type = 'group',
			name = L['Power'],
			get = function(info) return E.db.unitframe.units['party']['power'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['party']['power'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('party') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},			
				text = {
					type = 'toggle',
					order = 2,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 3,
					name = L['Text Format'],
					values = textFormats,
				},
				width = {
					type = 'select',
					order = 4,
					name = L['Width'],
					values = fillValues,
				},
				height = {
					type = 'range',
					name = L['Height'],
					order = 5,
					min = 2, max = 50, step = 1,
				},
				offset = {
					type = 'range',
					name = L['Offset'],
					desc = L['Offset of the powerbar to the healthbar, set to 0 to disable.'],
					order = 6,
					min = 0, max = 20, step = 1,
				},
				hideonnpc = {
					type = 'toggle',
					order = 7,
					name = L['Text Toggle On NPC'],
					desc = L['Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point.'],
				},
				position = {
					type = 'select',
					order = 8,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},	
		name = {
			order = 300,
			type = 'group',
			name = L['Name'],
			get = function(info) return E.db.unitframe.units['party']['name'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['party']['name'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('party') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},			
				length = {
					type = 'select',
					order = 3,
					name = L['Length'],
					values = lengthValues,				
				},
			},
		},
		buffs = {
			order = 400,
			type = 'group',
			name = L['Buffs'],
			get = function(info) return E.db.unitframe.units['party']['buffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['party']['buffs'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('party') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['DEBUFFS'] = L['Debuffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},				
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},		
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},	
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		debuffs = {
			order = 500,
			type = 'group',
			name = L['Debuffs'],
			get = function(info) return E.db.unitframe.units['party']['debuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['party']['debuffs'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('party') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['BUFFS'] = L['Buffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},	
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		buffIndicator = {
			order = 600,
			type = 'group',
			name = L['Buff Indicator'],
			get = function(info) return E.db.unitframe.units['party']['buffIndicator'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['party']['buffIndicator'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('party') end,
			args = {
				enable = {
					type = 'toggle',
					name = L['Enable'],
					order = 1,
				},
				colorIcons = {
					type = 'toggle',
					name = L['Color Icons'],
					desc = L['Color the icon to their set color in the filters section, otherwise use the icon texture.'],
					order = 2,					
				},
				size = {
					type = 'range',
					name = L['Size'],
					desc = L['Size of the indicator icon.'],
					order = 3,
					min = 4, max = 15, step = 1,
				},
				fontsize = {
					type = 'range',
					name = L['Font Size'],
					order = 4,
					min = 7, max = 22, step = 1,
				},
			},
		},
		roleIcon = {
			order = 700,
			type = 'group',
			name = L['Role Icon'],
			get = function(info) return E.db.unitframe.units['party']['roleIcon'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['party']['roleIcon'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('party') end,	
			args = {
				enable = {
					type = 'toggle',
					name = L['Enable'],
					order = 1,
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},							
			},
		},
		petsGroup = {
			order = 800,
			type = 'group',
			name = L['Party Pets'],
			get = function(info) return E.db.unitframe.units['party']['petsGroup'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['party']['petsGroup'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('party') end,	
			args = {		
				enable = {
					type = 'toggle',
					name = L['Enable'],
					order = 1,
				},
				width = {
					order = 2,
					name = L['Width'],
					type = 'range',
					min = 10, max = 500, step = 1,
				},			
				height = {
					order = 3,
					name = L['Height'],
					type = 'range',
					min = 10, max = 250, step = 1,
				},	
				initialAnchor = {
					type = 'select',
					order = 4,
					name = L['Initial Anchor'],
					values = petAnchors,
				},	
				anchorPoint = {
					type = 'select',
					order = 5,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = petAnchors,				
				},	
				xOffset = {
					order = 6,
					type = 'range',
					name = L['xOffset'],
					desc = L['An X offset (in pixels) to be used when anchoring new frames.'],
					min = -15, max = 15, step = 1,		
				},
				yOffset = {
					order = 7,
					type = 'range',
					name = L['yOffset'],
					desc = L['An Y offset (in pixels) to be used when anchoring new frames.'],
					min = -15, max = 15, step = 1,		
				},					
			},
		},
		targetsGroup = {
			order = 900,
			type = 'group',
			name = L['Party Targets'],
			get = function(info) return E.db.unitframe.units['party']['targetsGroup'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['party']['targetsGroup'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('party') end,	
			args = {		
				enable = {
					type = 'toggle',
					name = L['Enable'],
					order = 1,
				},
				width = {
					order = 2,
					name = L['Width'],
					type = 'range',
					min = 10, max = 500, step = 1,
				},			
				height = {
					order = 3,
					name = L['Height'],
					type = 'range',
					min = 10, max = 250, step = 1,
				},	
				initialAnchor = {
					type = 'select',
					order = 4,
					name = L['Initial Anchor'],
					values = petAnchors,
				},	
				anchorPoint = {
					type = 'select',
					order = 5,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = petAnchors,				
				},	
				xOffset = {
					order = 6,
					type = 'range',
					name = L['xOffset'],
					desc = L['An X offset (in pixels) to be used when anchoring new frames.'],
					min = -15, max = 15, step = 1,		
				},
				yOffset = {
					order = 7,
					type = 'range',
					name = L['yOffset'],
					desc = L['An Y offset (in pixels) to be used when anchoring new frames.'],
					min = -15, max = 15, step = 1,		
				},					
			},
		},		
	},
}

--Raid625 Frames
E.Options.args.unitframe.args.raid625 = {
	name = L['Raid625 Frames'],
	type = 'group',
	order = 1100,
	childGroups = "select",
	get = function(info) return E.db.unitframe.units['raid625'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['raid625'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid625') end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		resetSettings = {
			type = 'execute',
			order = 2,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('raid625') end,
		},			
		general = {
			order = 5,
			type = 'group',
			name = L['General'],
			args = {
				width = {
					order = 2,
					name = L['Width'],
					type = 'range',
					min = 50, max = 500, step = 1,
				},			
				height = {
					order = 3,
					name = L['Height'],
					type = 'range',
					min = 10, max = 250, step = 1,
				},	
				point = {
					order = 4,
					type = 'select',
					name = L['Group Point'],
					desc = L['What each frame should attach itself to, example setting it to TOP every unit will attach its top to the last point bottom.'],
					values = groupPoints,
					set = function(info, value) E.db.unitframe.units['raid625'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid625'); end,
				},
				columnAnchorPoint = {
					order = 5,
					type = 'select',
					name = L['Column Point'],
					desc = L['The anchor point for each new column. A value of LEFT will cause the columns to grow to the right.'],
					values = groupPoints,	
					set = function(info, value) E.db.unitframe.units['raid625'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid625'); end,
				},
				maxColumns = {
					order = 6,
					type = 'range',
					name = L['Max Columns'],
					desc = L['The maximum number of columns that the header will create.'],
					min = 1, max = 40, step = 1,
				},
				unitsPerColumn = {
					order = 7,
					type = 'range',
					name = L['Units Per Column'],
					desc = L['The maximum number of units that will be displayed in a single column.'],
					min = 1, max = 40, step = 1,
				},
				columnSpacing = {
					order = 8,
					type = 'range',
					name = L['Column Spacing'],
					desc = L['The amount of space (in pixels) between the columns.'],
					min = 3, max = 10, step = 1,
				},		
				xOffset = {
					order = 9,
					type = 'range',
					name = L['xOffset'],
					desc = L['An X offset (in pixels) to be used when anchoring new frames.'],
					min = -15, max = 15, step = 1,		
				},
				yOffset = {
					order = 10,
					type = 'range',
					name = L['yOffset'],
					desc = L['An Y offset (in pixels) to be used when anchoring new frames.'],
					min = -15, max = 15, step = 1,		
				},		
				showParty = {
					order = 11,
					type = 'toggle',
					name = L['Show Party'],
					desc = L['When true, the group header is shown when the player is in a party.'],
				},
				showRaid = {
					order = 12,
					type = 'toggle',
					name = L['Show Raid'],
					desc = L['When true, the group header is shown when the player is in a raid.'],
				},	
				showSolo = {
					order = 13,
					type = 'toggle',
					name = L['Show Solo'],
					desc = L['When true, the header is shown when the player is not in any group.'],		
				},
				showPlayer = {
					order = 14,
					type = 'toggle',
					name = L['Display Player'],
					desc = L['When true, the header includes the player when not in a raid.'],			
				},
				healPrediction = {
					order = 15,
					name = L['Heal Prediction'],
					desc = L['Show a incomming heal prediction bar on the unitframe. Also display a slightly different colored bar for incoming overheals.'],
					type = 'toggle',
				},	
				groupBy = {
					order = 16,
					name = L['Group By'],
					desc = L['Set the order that the group will sort.'],
					type = 'select',		
					values = {
						['CLASS'] = CLASS,
						['TANK'] = L["Tanks First"],
						['GROUP'] = GROUP,
					},
				},			
				visibility = {
					order = 200,
					type = 'input',
					name = L['Visibility'],
					desc = L['The following macro must be true in order for the group to be shown, in addition to any filter that may already be set.'],
					width = 'full',
				},					
			},
		},
		health = {
			order = 100,
			type = 'group',
			name = L['Health'],
			get = function(info) return E.db.unitframe.units['raid625']['health'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid625']['health'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid625'); end,
			args = {
				text = {
					type = 'toggle',
					order = 1,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 2,
					name = L['Text Format'],
					values = textFormats,
				},
				position = {
					type = 'select',
					order = 3,
					name = L['Position'],
					values = positionValues,
				},					
				frequentUpdates = {
					type = 'toggle',
					order = 4,
					name = L['Frequent Updates'],
					desc = L['Rapidly update the health, uses more memory and cpu. Only recommended for healing.'],
				},
				orientation = {
					type = 'select',
					order = 5,
					name = L['Orientation'],
					desc = L['Direction the health bar moves when gaining/losing health.'],
					values = {
						['HORIZONTAL'] = L['Horizontal'],
						['VERTICAL'] = L['Vertical'],
					},
				},	
			},
		},
		power = {
			order = 200,
			type = 'group',
			name = L['Power'],
			get = function(info) return E.db.unitframe.units['raid625']['power'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid625']['power'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid625') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},			
				text = {
					type = 'toggle',
					order = 2,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 3,
					name = L['Text Format'],
					values = textFormats,
				},
				width = {
					type = 'select',
					order = 4,
					name = L['Width'],
					values = fillValues,
				},
				height = {
					type = 'range',
					name = L['Height'],
					order = 5,
					min = 2, max = 50, step = 1,
				},
				offset = {
					type = 'range',
					name = L['Offset'],
					desc = L['Offset of the powerbar to the healthbar, set to 0 to disable.'],
					order = 6,
					min = 0, max = 20, step = 1,
				},
				hideonnpc = {
					type = 'toggle',
					order = 7,
					name = L['Text Toggle On NPC'],
					desc = L['Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point.'],
				},
				position = {
					type = 'select',
					order = 8,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},	
		name = {
			order = 300,
			type = 'group',
			name = L['Name'],
			get = function(info) return E.db.unitframe.units['raid625']['name'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid625']['name'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid625') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},		
				length = {
					type = 'select',
					order = 3,
					name = L['Length'],
					values = lengthValues,				
				},				
			},
		},
		buffs = {
			order = 400,
			type = 'group',
			name = L['Buffs'],
			get = function(info) return E.db.unitframe.units['raid625']['buffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid625']['buffs'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid625') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['DEBUFFS'] = L['Debuffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},				
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},		
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},	
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		debuffs = {
			order = 500,
			type = 'group',
			name = L['Debuffs'],
			get = function(info) return E.db.unitframe.units['raid625']['debuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid625']['debuffs'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid625') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['BUFFS'] = L['Buffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},	
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		buffIndicator = {
			order = 600,
			type = 'group',
			name = L['Buff Indicator'],
			get = function(info) return E.db.unitframe.units['raid625']['buffIndicator'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid625']['buffIndicator'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid625') end,
			args = {
				enable = {
					type = 'toggle',
					name = L['Enable'],
					order = 1,
				},
				colorIcons = {
					type = 'toggle',
					name = L['Color Icons'],
					desc = L['Color the icon to their set color in the filters section, otherwise use the icon texture.'],
					order = 2,					
				},
				size = {
					type = 'range',
					name = L['Size'],
					desc = L['Size of the indicator icon.'],
					order = 3,
					min = 4, max = 15, step = 1,
				},
				fontsize = {
					type = 'range',
					name = L['Font Size'],
					order = 4,
					min = 7, max = 22, step = 1,
				},
			},
		},
		roleIcon = {
			order = 700,
			type = 'group',
			name = L['Role Icon'],
			get = function(info) return E.db.unitframe.units['raid625']['roleIcon'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid625']['roleIcon'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid625') end,	
			args = {
				enable = {
					type = 'toggle',
					name = L['Enable'],
					order = 1,
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},							
			},
		},		
		rdebuffs = {
			order = 800,
			type = 'group',
			name = L['RaidDebuff Indicator'],
			get = function(info) return E.db.unitframe.units['raid625']['rdebuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid625']['rdebuffs'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid625') end,
			args = {
				enable = {
					type = 'toggle',
					name = L['Enable'],
					order = 1,
				},	
				size = {
					type = 'range',
					name = L['Size'],
					order = 2,
					min = 8, max = 35, step = 1,
				},				
				fontsize = {
					type = 'range',
					name = L['Font Size'],
					order = 3,
					min = 7, max = 22, step = 1,
				},				
			},
		},		
	},
}

--Raid2640 Frames
E.Options.args.unitframe.args.raid2640 = {
	name = L['Raid2640 Frames'],
	type = 'group',
	order = 1100,
	childGroups = "select",
	get = function(info) return E.db.unitframe.units['raid2640'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['raid2640'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid2640') end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		resetSettings = {
			type = 'execute',
			order = 2,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('raid2640') end,
		},			
		general = {
			order = 5,
			type = 'group',
			name = L['General'],
			args = {
				width = {
					order = 2,
					name = L['Width'],
					type = 'range',
					min = 50, max = 500, step = 1,
				},			
				height = {
					order = 3,
					name = L['Height'],
					type = 'range',
					min = 10, max = 250, step = 1,
				},	
				point = {
					order = 4,
					type = 'select',
					name = L['Group Point'],
					desc = L['What each frame should attach itself to, example setting it to TOP every unit will attach its top to the last point bottom.'],
					values = groupPoints,
					set = function(info, value) E.db.unitframe.units['raid2640'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid2640'); end,
				},
				columnAnchorPoint = {
					order = 5,
					type = 'select',
					name = L['Column Point'],
					desc = L['The anchor point for each new column. A value of LEFT will cause the columns to grow to the right.'],
					values = groupPoints,	
					set = function(info, value) E.db.unitframe.units['raid2640'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid2640'); end,
				},
				maxColumns = {
					order = 6,
					type = 'range',
					name = L['Max Columns'],
					desc = L['The maximum number of columns that the header will create.'],
					min = 1, max = 40, step = 1,
				},
				unitsPerColumn = {
					order = 7,
					type = 'range',
					name = L['Units Per Column'],
					desc = L['The maximum number of units that will be displayed in a single column.'],
					min = 1, max = 40, step = 1,
				},
				columnSpacing = {
					order = 8,
					type = 'range',
					name = L['Column Spacing'],
					desc = L['The amount of space (in pixels) between the columns.'],
					min = 3, max = 10, step = 1,
				},		
				xOffset = {
					order = 9,
					type = 'range',
					name = L['xOffset'],
					desc = L['An X offset (in pixels) to be used when anchoring new frames.'],
					min = -15, max = 15, step = 1,		
				},
				yOffset = {
					order = 10,
					type = 'range',
					name = L['yOffset'],
					desc = L['An Y offset (in pixels) to be used when anchoring new frames.'],
					min = -15, max = 15, step = 1,		
				},		
				showParty = {
					order = 11,
					type = 'toggle',
					name = L['Show Party'],
					desc = L['When true, the group header is shown when the player is in a party.'],
				},
				showRaid = {
					order = 12,
					type = 'toggle',
					name = L['Show Raid'],
					desc = L['When true, the group header is shown when the player is in a raid.'],
				},	
				showSolo = {
					order = 13,
					type = 'toggle',
					name = L['Show Solo'],
					desc = L['When true, the header is shown when the player is not in any group.'],		
				},
				showPlayer = {
					order = 14,
					type = 'toggle',
					name = L['Display Player'],
					desc = L['When true, the header includes the player when not in a raid.'],			
				},
				healPrediction = {
					order = 15,
					name = L['Heal Prediction'],
					desc = L['Show a incomming heal prediction bar on the unitframe. Also display a slightly different colored bar for incoming overheals.'],
					type = 'toggle',
				},		
				groupBy = {
					order = 16,
					name = L['Group By'],
					desc = L['Set the order that the group will sort.'],
					type = 'select',		
					values = {
						['CLASS'] = CLASS,
						['TANK'] = L["Tanks First"],
						['GROUP'] = GROUP,
					},
				},		
				visibility = {
					order = 200,
					type = 'input',
					name = L['Visibility'],
					desc = L['The following macro must be true in order for the group to be shown, in addition to any filter that may already be set.'],
					width = 'full',
				},					
			},
		},
		health = {
			order = 100,
			type = 'group',
			name = L['Health'],
			get = function(info) return E.db.unitframe.units['raid2640']['health'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid2640']['health'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid2640'); end,
			args = {
				text = {
					type = 'toggle',
					order = 1,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 2,
					name = L['Text Format'],
					values = textFormats,
				},
				position = {
					type = 'select',
					order = 3,
					name = L['Position'],
					values = positionValues,
				},					
				frequentUpdates = {
					type = 'toggle',
					order = 4,
					name = L['Frequent Updates'],
					desc = L['Rapidly update the health, uses more memory and cpu. Only recommended for healing.'],
				},
				orientation = {
					type = 'select',
					order = 5,
					name = L['Orientation'],
					desc = L['Direction the health bar moves when gaining/losing health.'],
					values = {
						['HORIZONTAL'] = L['Horizontal'],
						['VERTICAL'] = L['Vertical'],
					},
				},	
			},
		},
		power = {
			order = 200,
			type = 'group',
			name = L['Power'],
			get = function(info) return E.db.unitframe.units['raid2640']['power'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid2640']['power'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid2640') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},			
				text = {
					type = 'toggle',
					order = 2,
					name = L['Text'],
				},
				text_format = {
					type = 'select',
					order = 3,
					name = L['Text Format'],
					values = textFormats,
				},
				width = {
					type = 'select',
					order = 4,
					name = L['Width'],
					values = fillValues,
				},
				height = {
					type = 'range',
					name = L['Height'],
					order = 5,
					min = 2, max = 50, step = 1,
				},
				offset = {
					type = 'range',
					name = L['Offset'],
					desc = L['Offset of the powerbar to the healthbar, set to 0 to disable.'],
					order = 6,
					min = 0, max = 20, step = 1,
				},
				hideonnpc = {
					type = 'toggle',
					order = 7,
					name = L['Text Toggle On NPC'],
					desc = L['Power text will be hidden on NPC targets, in addition the name text will be repositioned to the power texts anchor point.'],
				},
				position = {
					type = 'select',
					order = 8,
					name = L['Position'],
					values = positionValues,
				},					
			},
		},	
		name = {
			order = 300,
			type = 'group',
			name = L['Name'],
			get = function(info) return E.db.unitframe.units['raid2640']['name'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid2640']['name'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid2640') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},	
				length = {
					type = 'select',
					order = 3,
					name = L['Length'],
					values = lengthValues,				
				},				
			},
		},
		buffs = {
			order = 400,
			type = 'group',
			name = L['Buffs'],
			get = function(info) return E.db.unitframe.units['raid2640']['buffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid2640']['buffs'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid2640') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['DEBUFFS'] = L['Debuffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},				
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},		
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},	
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		debuffs = {
			order = 500,
			type = 'group',
			name = L['Debuffs'],
			get = function(info) return E.db.unitframe.units['raid2640']['debuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid2640']['debuffs'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid2640') end,
			args = {
				enable = {
					type = 'toggle',
					order = 1,
					name = L['Enable'],
				},
				perrow = {
					type = 'range',
					order = 2,
					name = L['Per Row'],
					min = 1, max = 20, step = 1,
				},
				numrows = {
					type = 'range',
					order = 3,
					name = L['Num Rows'],
					min = 1, max = 4, step = 1,					
				},
				sizeOverride = {
					type = 'range',
					order = 3,
					name = L['Size Override'],
					desc = L['If not set to 0 then override the size of the aura icon to this.'],
					min = 0, max = 60, step = 1,
				},				
				['growth-x'] = {
					type = 'select',
					order = 4,
					name = L['X-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['LEFT'] = L['Left'],
						['RIGHT'] = L["Right"],
					},
				},
				['growth-y'] = {
					type = 'select',
					order = 5,
					name = L['Y-Growth'],
					desc = L['Growth direction of the buffs'],
					values = {
						['UP'] = L['Up'],
						['DOWN'] = L["Down"],
					},
				},	
				initialAnchor = {
					type = 'select',
					order = 6,
					name = L['Initial Anchor'],
					desc = L['The initial anchor point of the buffs on the frame'],
					values = auraAnchors,
				},	
				attachTo = {
					type = 'select',
					order = 7,
					name = L['Attach To'],
					desc = L['What to attach the buff anchor frame to.'],
					values = {
						['FRAME'] = L['Frame'],
						['BUFFS'] = L['Buffs'],
					},
				},
				anchorPoint = {
					type = 'select',
					order = 8,
					name = L['Anchor Point'],
					desc = L['What point to anchor to the frame you set to attach to.'],
					values = auraAnchors,				
				},
				fontsize = {
					order = 6,
					name = L["Font Size"],
					type = "range",
					min = 6, max = 22, step = 1,
				},	
				useFilter = {
					order = 7,
					name = L['Use Filter'],
					desc = L['Select a filter to use.'],
					type = 'select',
					values = function()
						filters = {}
						filters[''] = ''
						for filter in pairs(E.global.unitframe['aurafilters']) do
							filters[filter] = filter
						end
						return filters
					end,
				},
				showPlayerOnly = {
					order = 8,
					type = 'toggle',
					name = L['Personal Auras'],
					desc = L['If set only auras belonging to yourself in addition to any aura that passes the set filter may be shown.'],
				},
				durationLimit = {
					order = 9,
					name = L['Duration Limit'],
					desc = L['The aura must be below this duration for the buff to show, set to 0 to disable. Note: This is in seconds.'],
					type = 'range',
					min = 0, max = 3600, step = 60,
				},					
			},
		},	
		buffIndicator = {
			order = 600,
			type = 'group',
			name = L['Buff Indicator'],
			get = function(info) return E.db.unitframe.units['raid2640']['buffIndicator'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid2640']['buffIndicator'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid2640') end,
			args = {
				enable = {
					type = 'toggle',
					name = L['Enable'],
					order = 1,
				},
				colorIcons = {
					type = 'toggle',
					name = L['Color Icons'],
					desc = L['Color the icon to their set color in the filters section, otherwise use the icon texture.'],
					order = 2,					
				},
				size = {
					type = 'range',
					name = L['Size'],
					desc = L['Size of the indicator icon.'],
					order = 3,
					min = 4, max = 15, step = 1,
				},
				fontsize = {
					type = 'range',
					name = L['Font Size'],
					order = 4,
					min = 7, max = 22, step = 1,
				},
			},
		},	
		roleIcon = {
			order = 700,
			type = 'group',
			name = L['Role Icon'],
			get = function(info) return E.db.unitframe.units['raid625']['roleIcon'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid625']['roleIcon'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid625') end,	
			args = {
				enable = {
					type = 'toggle',
					name = L['Enable'],
					order = 1,
				},
				position = {
					type = 'select',
					order = 2,
					name = L['Position'],
					values = positionValues,
				},							
			},
		},		
		rdebuffs = {
			order = 800,
			type = 'group',
			name = L['RaidDebuff Indicator'],
			get = function(info) return E.db.unitframe.units['raid625']['rdebuffs'][ info[#info] ] end,
			set = function(info, value) E.db.unitframe.units['raid625']['rdebuffs'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('raid625') end,
			args = {
				enable = {
					type = 'toggle',
					name = L['Enable'],
					order = 1,
				},	
				size = {
					type = 'range',
					name = L['Size'],
					order = 2,
					min = 8, max = 35, step = 1,
				},				
				fontsize = {
					type = 'range',
					name = L['Font Size'],
					order = 3,
					min = 7, max = 22, step = 1,
				},				
			},
		},		
	},
}

--Tank Frames
E.Options.args.unitframe.args.tank = {
	name = L['Tank Frames'],
	type = 'group',
	order = 1100,
	get = function(info) return E.db.unitframe.units['tank'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['tank'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('tank') end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		resetSettings = {
			type = 'execute',
			order = 2,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('tank') end,
		},		
		general = {
			order = 3,
			type = 'group',
			name = L['General'],
			guiInline = true,
			args = {
				width = {
					order = 2,
					name = L['Width'],
					type = 'range',
					min = 50, max = 500, step = 1,
				},			
				height = {
					order = 3,
					name = L['Height'],
					type = 'range',
					min = 10, max = 250, step = 1,
				},					
			},
		},	
	},
}

--Assist Frames
E.Options.args.unitframe.args.assist = {
	name = L['Assist Frames'],
	type = 'group',
	order = 1100,
	get = function(info) return E.db.unitframe.units['assist'][ info[#info] ] end,
	set = function(info, value) E.db.unitframe.units['assist'][ info[#info] ] = value; UF:CreateAndUpdateHeaderGroup('assist') end,
	args = {
		enable = {
			type = 'toggle',
			order = 1,
			name = L['Enable'],
		},
		resetSettings = {
			type = 'execute',
			order = 2,
			name = L['Restore Defaults'],
			func = function(info, value) UF:ResetUnitSettings('assist') end,
		},		
		general = {
			order = 3,
			type = 'group',
			name = L['General'],
			guiInline = true,
			args = {
				width = {
					order = 2,
					name = L['Width'],
					type = 'range',
					min = 50, max = 500, step = 1,
				},			
				height = {
					order = 3,
					name = L['Height'],
					type = 'range',
					min = 10, max = 250, step = 1,
				},					
			},
		},	
	},
}
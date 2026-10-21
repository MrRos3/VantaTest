"""Logic tests with Lua engine doubles. Real Roblox rendering/permissions require Studio."""
from pathlib import Path
import unittest
from lupa import LuaRuntime
from lupa.lua51 import LuaRuntime as Lua51

ROOT = Path(__file__).resolve().parents[1]


class ChatTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime()
        self.lua.execute((ROOT / 'tests/chat_mock.lua').read_text(encoding='utf-8'))

    def runlua(self, code):
        self.lua.execute(code)

    def server(self):
        self.lua.execute((ROOT / 'roblox-chat/Server.server.lua').read_text(encoding='utf-8'))

    def mount(self):
        self.lua.globals().Chat = self.lua.execute((ROOT / 'chat.lua').read_text(encoding='utf-8'))
        self.runlua('Chat.Mount({UIElements={ContainerFrame=holder}})')

    def test_lua51_syntax(self):
        compile_lua = Lua51().eval('function(s) local f,e=loadstring(s);assert(f,e) end')
        for path in [ROOT/'chat.lua', ROOT/'example.lua', *ROOT.glob('roblox-chat/*.lua')]:
            compile_lua(path.read_text(encoding='utf-8'))

    def test_missing_server_disables_send_without_samples(self):
        self.mount()
        self.runlua('assert(not find("ComposerInput").TextEditable);assert(not allText():find("DEMO"))')

    def test_icon_failure_uses_same_asset_thumbnail_and_visible_label(self):
        self.runlua('unloadedIcons=true')
        self.mount()
        self.runlua('''
            local icon=find("SaltyIcon_send")
            assert(icon.Image=="rbxthumb://type=Asset&id=104783825572790&w=150&h=150")
            assert(icon.ZIndex>icon.Parent.ZIndex)
            assert(not icon.Visible)
            assert(allText():find("Send",1,true))
        ''')

    def test_filtered_receive_and_no_local_echo(self):
        self.server()
        self.mount()
        self.runlua('''
            local entry=find("ComposerInput")
            assert(entry.TextEditable)
            entry.Text="raw draft"
            find("SendMessage").MouseButton1Click:Fire()
            assert(channels:FindFirstChild("VantaEN").sent=="raw draft")
            assert(not allText():find("raw draft",1,true))
            tcs.MessageReceived:Fire({Status=Enum.TextChatMessageStatus.Success,
                TextChannel=channels:FindFirstChild("VantaEN"),TextSource={UserId=22},
                MessageId="one",Text="filtered result"})
            assert(allText():find("filtered result",1,true))
            local before=#objects
            tcs.MessageReceived:Fire({Status=Enum.TextChatMessageStatus.Success,
                TextChannel=channels:FindFirstChild("VantaEN"),TextSource={UserId=22},
                MessageId="one",Text="duplicate must not appear"})
            assert(#objects==before)
            tcs.MessageReceived:Fire({Status=Enum.TextChatMessageStatus.Sending,
                TextChannel=channels:FindFirstChild("VantaEN"),TextSource={UserId=11},
                MessageId="pending",Text="unfiltered pending content"})
            assert(not allText():find("unfiltered pending content",1,true))
            entry.Text="keep on failure";sendError=true
            find("SendMessage").MouseButton1Click:Fire()
            assert(entry.Text=="keep on failure")
        ''')

    def test_friend_dm_permissions_throttle_and_cleanup(self):
        self.server()
        self.runlua('''
            local remote=storage:FindFirstChild("VantaChatOpen")
            assert(remote.OnServerInvoke(me,22)=="VantaDM_11_22")
            assert(remote.OnServerInvoke(me,22)==nil) -- rate limit
            now=now+3;permissionDenied=true
            assert(remote.OnServerInvoke(me,22)==nil) -- existing DM still checks permissions
            now=now+3;permissionDenied=false;friendsAllowed=false
            assert(remote.OnServerInvoke(me,22)==nil)
            now=now+3;friendsAllowed=true
            assert(remote.OnServerInvoke(me,999)==nil) -- no cross-server relay
            now=now+3
            assert(remote.OnServerInvoke(me,"message text")==nil)
            players.PlayerRemoving:Fire(friend)
            assert(not channels:FindFirstChild("VantaDM_11_22"))
        ''')

    def test_admission_failure_never_publishes_ready_dm(self):
        self.server()
        self.runlua('''
            admissionDenied=true
            assert(storage:FindFirstChild("VantaChatOpen").OnServerInvoke(me,22)==nil)
            assert(not channels:FindFirstChild("VantaDM_11_22"))
        ''')

    def test_ui_friend_selection_routes_to_dm(self):
        self.server()
        self.mount()
        self.runlua('''
            find("ChooseFriend").MouseButton1Click:Fire()
            find("Friend_22").MouseButton1Click:Fire()
            find("ComposerInput").Text="private draft"
            find("SendMessage").MouseButton1Click:Fire()
            assert(channels:FindFirstChild("VantaDM_11_22").sent=="private draft")
            assert(channels:FindFirstChild("VantaEN").sent==nil)
            assert(not allText():find("private draft",1,true))
        ''')

    def test_existing_game_chat_works_without_vanta_server(self):
        self.runlua('existingChat()')
        self.mount()
        self.runlua('''
            assert(find("ComposerInput").TextEditable)
            find("ComposerInput").Text="room draft"
            find("SendMessage").MouseButton1Click:Fire()
            assert(channels:FindFirstChild("RBXGeneral").sent=="room draft")
            tcs.MessageReceived:Fire({Status=Enum.TextChatMessageStatus.Success,
                TextChannel=channels:FindFirstChild("RBXGeneral"),TextSource={UserId=22},
                MessageId="game-one",Text="filtered game message"})
            assert(allText():find("filtered game message",1,true))
        ''')

    def test_native_whisper_command_only_sends_recipient_then_private_body(self):
        self.runlua('existingChat();commandCreatesWhisper=true')
        self.mount()
        self.runlua('''
            find("ChooseFriend").MouseButton1Click:Fire()
            find("Friend_22").MouseButton1Click:Fire()
            assert(channels:FindFirstChild("RBXGeneral").sent=="/whisper @Bob")
            find("ComposerInput").Text="private draft"
            find("SendMessage").MouseButton1Click:Fire()
            assert(channels:FindFirstChild("RBXWhisper:11_22").sent=="private draft")
            assert(channels:FindFirstChild("RBXGeneral").sent=="/whisper @Bob")
        ''')

    def test_failed_private_open_never_falls_back_to_public(self):
        self.runlua('existingChat()')
        self.mount()
        self.runlua('''
            find("ChooseFriend").MouseButton1Click:Fire()
            find("Friend_22").MouseButton1Click:Fire()
            assert(not find("ComposerInput").TextEditable)
            find("ComposerInput").Text="private draft"
            find("SendMessage").MouseButton1Click:Fire()
            assert(channels:FindFirstChild("RBXGeneral").sent=="/whisper @Bob")
        ''')

    def test_lost_private_channel_never_selects_public(self):
        self.runlua('existingChat();commandCreatesWhisper=true')
        self.mount()
        self.runlua('''
            find("ChooseFriend").MouseButton1Click:Fire()
            find("Friend_22").MouseButton1Click:Fire()
            local private=channels:FindFirstChild("RBXWhisper:11_22")
            private:Destroy();channels.ChildRemoved:Fire(private)
            assert(not find("ComposerInput").TextEditable)
            find("ComposerInput").Text="private after departure"
            find("SendMessage").MouseButton1Click:Fire()
            assert(channels:FindFirstChild("RBXGeneral").sent=="/whisper @Bob")
        ''')

    def test_popups_are_exclusive_and_friend_panel_clips_content(self):
        self.mount()
        self.runlua('''
            find("EmojiPickerToggle").MouseButton1Click:Fire()
            assert(find("EmojiPicker").Visible)
            find("ChooseFriend").MouseButton1Click:Fire()
            assert(find("FriendChoices").Visible and not find("EmojiPicker").Visible)
            assert(find("FriendChoices").ClipsDescendants)
            find("EmojiPickerToggle").MouseButton1Click:Fire()
            assert(not find("FriendChoices").Visible and find("EmojiPicker").Visible)
        ''')

    def test_system_chat_toggle_restores_original_settings_on_destroy(self):
        self.runlua('existingChat()')
        self.mount()
        self.runlua('''
            find("SystemChatToggle").MouseButton1Click:Fire()
            assert(not tcs:FindFirstChild("ChatWindowConfiguration").Enabled)
            assert(not tcs:FindFirstChild("ChatInputBarConfiguration").Enabled)
            find("VantaChatExperiment"):Destroy()
            assert(tcs:FindFirstChild("ChatWindowConfiguration").Enabled)
            assert(tcs:FindFirstChild("ChatInputBarConfiguration").Enabled)
        ''')

    def test_read_only_source_disables_composer(self):
        self.server()
        self.runlua('''
            for _,source in ipairs(channels:FindFirstChild("VantaEN"):GetChildren())do
                if source.UserId==11 then source.CanSend=false end
            end
        ''')
        self.mount()
        self.runlua('assert(not find("ComposerInput").TextEditable)')

    def test_native_mode_explicit_attribute_when_property_is_unavailable(self):
        self.server()
        self.runlua('storage:SetAttribute("VantaPlatformIntegratedChat",true)')
        self.mount()
        self.runlua('assert(find("RobloxChatWindow"));assert(not find("Composer").Visible)')

    def test_native_integrated_window_owns_input(self):
        self.server()
        self.runlua('tcs.PlatformIntegratedChat=Enum.RolloutState.Enabled')
        self.mount()
        self.runlua('''
            assert(find("RobloxChatWindow").Target==channels:FindFirstChild("VantaEN"))
            assert(not find("Composer").Visible)
            assert(not find("ComposerInput").TextEditable)
        ''')


if __name__ == '__main__':
    unittest.main()



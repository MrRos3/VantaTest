"""Lua logic tests. Engine doubles are not real Roblox filtering or delivery proof."""
from pathlib import Path
import hashlib
import json
import struct
import unittest
from lupa import LuaRuntime
from lupa.lua51 import LuaRuntime as Lua51
ROOT=Path(__file__).resolve().parents[1]
class ChatTests(unittest.TestCase):
    def setUp(self):
        self.lua=LuaRuntime()
        self.lua.execute((ROOT/'tests/chat_mock.lua').read_text(encoding='utf-8'))
    def runlua(self,code): self.lua.execute(code)
    def server(self,join=True):
        self.lua.execute((ROOT/'roblox-chat/Server.server.lua').read_text(encoding='utf-8'))
        if join:
            self.runlua("local a,b; a,b,aliceLease=storage:FindFirstChild('VantaChatMembership').OnServerInvoke(me,'join');assert(a);a,b,bobLease=storage:FindFirstChild('VantaChatMembership').OnServerInvoke(friend,'join');assert(a)")
    def mount(self,resolver=None):
        self.lua.globals().Transport=self.lua.execute((ROOT/'roblox-chat/Transport.lua').read_text(encoding='utf-8'))
        self.lua.globals().Chat=self.lua.execute((ROOT/'chat.lua').read_text(encoding='utf-8'))
        self.runlua("Chat.Mount({UIElements={ContainerFrame=holder}},{Transport=Transport.new(),IconResolver="+(resolver or 'nil')+"})")
    def test_lua51_syntax(self):
        compile=Lua51().eval('function(s)local f,e=loadstring(s);assert(f,e)end')
        for p in [ROOT/'chat.lua',ROOT/'example.lua',*ROOT.glob('roblox-chat/*.lua')]: compile(p.read_text(encoding='utf-8'))
    def test_no_automatic_membership_or_public_fallback(self):
        self.server(False)
        self.runlua("existingChat();assert(#channels:FindFirstChild('VantaEN'):GetChildren()==0)")
        self.mount()
        self.runlua("find('ComposerInput').Text='vanta only';find('SendMessage').MouseButton1Click:Fire();assert(channels:FindFirstChild('VantaEN').sent=='vanta only');assert(not channels:FindFirstChild('RBXGeneral').sent)")
    def test_missing_server_never_uses_general(self):
        self.runlua('existingChat()');self.mount()
        self.runlua("assert(not find('ComposerInput').TextEditable);find('ComposerInput').Text='private';find('SendMessage').MouseButton1Click:Fire();assert(not channels:FindFirstChild('RBXGeneral').sent)")
    def test_permissions_deny_admission_and_status(self):
        self.server(False);self.runlua('chatDenied=true');self.mount()
        self.runlua("assert(not me:GetAttribute('VantaChatJoined'));assert(not find('ComposerInput').TextEditable);assert(#channels:FindFirstChild('VantaEN'):GetChildren()==0)")
    def test_dedicated_display_mode_is_required(self):
        self.server(False);self.runlua('windowConfig.TextChannelDisplayMode=Enum.TextChannelDisplayMode.All')
        self.mount();self.runlua("assert(not me:GetAttribute('VantaChatJoined'));assert(not find('ComposerInput').TextEditable)")
    def test_stale_leave_cannot_remove_a_new_client_session(self):
        self.server()
        self.runlua("local r=storage:FindFirstChild('VantaChatMembership');local a,b,newLease=r.OnServerInvoke(me,'join');assert(a);assert(newLease~=aliceLease);assert(not r.OnServerInvoke(me,'leave',aliceLease));assert(me:GetAttribute('VantaChatJoined'));assert(r.OnServerInvoke(me,'leave',newLease));assert(not me:GetAttribute('VantaChatJoined'))")
    def test_two_clients_join_and_leave_removes_access(self):
        self.server()
        self.runlua("local c=channels:FindFirstChild('VantaEN');assert(#c:GetChildren()==2);local m={MessageId='first',TextSource={UserId=11}};assert(c.ShouldDeliverCallback(m,{UserId=22}));storage:FindFirstChild('VantaChatMembership').OnServerInvoke(friend,'leave',bobLease);assert(not c.ShouldDeliverCallback(m,{UserId=22}));assert(not friend:GetAttribute('VantaChatJoined'))")
    def test_friend_dm_requires_both_opted_in_and_permissions(self):
        self.server()
        self.runlua("local r=storage:FindFirstChild('VantaChatOpen');assert(r.OnServerInvoke(me,22)=='VantaDM_11_22');assert(not r.OnServerInvoke(me,22));now=now+3;permissionDenied=true;assert(not r.OnServerInvoke(me,22));now=now+3;permissionDenied=false;friendsAllowed=false;assert(not r.OnServerInvoke(me,22));now=now+3;friendsAllowed=true;storage:FindFirstChild('VantaChatMembership').OnServerInvoke(friend,'leave',bobLease);assert(not r.OnServerInvoke(me,22));assert(not channels:FindFirstChild('VantaDM_11_22'))")
    def test_admission_failure_rolls_back(self):
        self.server(False);self.runlua("admissionDenied=true;assert(not storage:FindFirstChild('VantaChatMembership').OnServerInvoke(me,'join'));assert(not me:GetAttribute('VantaChatJoined'))")
    def test_send_without_raw_echo_receive_dedup_and_failed_send(self):
        self.server();self.mount()
        self.runlua("local e=find('ComposerInput');e.Text='raw draft';find('SendMessage').MouseButton1Click:Fire();assert(channels:FindFirstChild('VantaEN').sent=='raw draft');assert(not allText():find('raw draft',1,true));local m={Status=Enum.TextChatMessageStatus.Success,TextChannel=channels:FindFirstChild('VantaEN'),TextSource={UserId=22},MessageId='one',Text='filtered result'};tcs.MessageReceived:Fire(m);assert(allText():find('filtered result',1,true));local before=#objects;tcs.MessageReceived:Fire(m);assert(#objects==before);e.Text='keep draft';sendError=true;find('SendMessage').MouseButton1Click:Fire();assert(e.Text=='keep draft')")
    def test_room_isolation_and_history_when_switching(self):
        self.server();self.mount()
        self.runlua("local m={Status=Enum.TextChatMessageStatus.Success,TextChannel=channels:FindFirstChild('VantaAR'),TextSource={UserId=22},MessageId='arabic',Text='Arabic room body'};tcs.MessageReceived:Fire(m);assert(not find('MessageFeed'):FindFirstChild('MessageBubble',true));find('AR').MouseButton1Click:Fire();assert(find('MessageFeed'):FindFirstChild('MessageBubble',true));find('EN').MouseButton1Click:Fire();assert(not find('MessageFeed'):FindFirstChild('MessageBubble',true));find('AR').MouseButton1Click:Fire();assert(find('MessageFeed'):FindFirstChild('MessageBubble',true))")
    def test_reaction_broadcasts_to_two_authorized_clients_and_toggles(self):
        self.server()
        self.runlua("local c=channels:FindFirstChild('VantaEN');assert(c.ShouldDeliverCallback({MessageId='msg',TextSource={UserId=11}},{UserId=22}));local r=storage:FindFirstChild('VantaChatReact');assert(r.OnServerInvoke(friend,'VantaEN','msg','👍'));local u=storage:FindFirstChild('VantaChatReactions');assert(#u.deliveries==2);assert(u.deliveries[1].payload.counts['👍']==1);now=now+1;assert(r.OnServerInvoke(friend,'VantaEN','msg','👍'));assert(u.deliveries[#u.deliveries].payload.counts['👍']==nil)")
    def test_reactions_reject_forgery_wrong_room_and_blocked_pairs(self):
        self.server()
        self.runlua("local c=channels:FindFirstChild('VantaEN');c.ShouldDeliverCallback({MessageId='msg',TextSource={UserId=11}},{UserId=22});local r=storage:FindFirstChild('VantaChatReact');assert(not r.OnServerInvoke(friend,'VantaAR','msg','👍'));now=now+1;assert(not r.OnServerInvoke(friend,'VantaEN','missing','👍'));now=now+1;assert(not r.OnServerInvoke(friend,'VantaEN','msg','free text'));now=now+1;pairDenied=true;assert(not r.OnServerInvoke(friend,'VantaEN','msg','👍'))")
    def test_message_rate_limit_counts_once_per_message(self):
        self.server()
        self.runlua("local c=channels:FindFirstChild('VantaEN');for i=1,4 do local m={MessageId=tostring(i),TextSource={UserId=11}};assert(c.ShouldDeliverCallback(m,{UserId=22}));assert(c.ShouldDeliverCallback(m,{UserId=11}))end;assert(not c.ShouldDeliverCallback({MessageId='fifth',TextSource={UserId=11}},{UserId=22}))")
    def test_popup_exclusivity_and_member_only_friend_cards(self):
        self.server();self.mount()
        self.runlua("find('EmojiPickerToggle').MouseButton1Click:Fire();assert(find('EmojiPicker').Visible);find('ChooseFriend').MouseButton1Click:Fire();assert(not find('EmojiPicker').Visible);assert(find('Friend_22'));assert(find('FriendChoices').ClipsDescendants);find('EmojiPickerToggle').MouseButton1Click:Fire();assert(not find('FriendChoices').Visible)")
    def test_no_fake_online_users_without_membership(self):
        self.runlua('existingChat()');self.mount()
        self.runlua("find('ChooseFriend').MouseButton1Click:Fire();assert(not find('Friend_22'));assert(not find('LocalServerAvatar'));assert(not allText():find('DEMO'))")
    def test_real_icon_resolver_preferred_over_decal(self):
        self.runlua("unloadedIcons=true;testResolver=function(key)return 'customasset://salty/'..key end")
        self.mount('testResolver')
        self.runlua("assert(find('SaltyIcon_send').Image=='customasset://salty/send')")
    def test_original_png_loader_checks_signature_and_cache(self):
        self.runlua("local files={};downloads=0;makefolder=function()end;readfile=function(p)return files[p]end;writefile=function(p,d)files[p]=d end;getcustomasset=function(p)return 'customasset://'..p end;game.HttpGet=function(_,url)downloads=downloads+1;assert(url:find('MrRos3/SaltyIcons/',1,true));return string.char(137)..'PNG'..string.char(13,10,26,10)..'original bytes'end")
        self.lua.globals().Icons=self.lua.execute((ROOT/'roblox-chat/IconAssets.lua').read_text(encoding='utf-8'))
        self.runlua("assert(Icons.Resolve('send')=='customasset://VantaTest/SaltyIcons-b7db826/send.png');assert(Icons.Resolve('send'));assert(downloads==1);assert(not Icons.Resolve('../anything'))")
    def test_all_packaged_salty_icons_match_original_hash_and_dimensions(self):
        assets=ROOT/'assets/salty-chat'
        entries=json.loads((assets/'manifest.json').read_text())
        self.assertEqual(len(entries),13)
        for entry in entries:
            data=(assets/(entry['key']+'.png')).read_bytes()
            self.assertEqual(hashlib.sha256(data).hexdigest(),entry['sha256'])
            self.assertEqual(data[:8],b'\x89PNG\r\n\x1a\n')
            self.assertEqual(struct.unpack('>II',data[16:24]),(96,96))
    def test_ui_shared_reaction_and_reply_metadata(self):
        self.server();self.mount()
        self.runlua("local c=channels:FindFirstChild('VantaEN');c.ShouldDeliverCallback({MessageId='reply-one',TextSource={UserId=22}},{UserId=11});tcs.MessageReceived:Fire({Status=Enum.TextChatMessageStatus.Success,TextChannel=c,TextSource={UserId=22},MessageId='reply-one',Text='filtered original'});find('MessageBubble').MouseButton1Click:Fire();find('Quick_like').MouseButton1Click:Fire();assert(allText():find('👍 1',1,true));find('MessageBubble').MouseButton1Click:Fire();find('Quick_reply').MouseButton1Click:Fire();find('ComposerInput').Text='reply draft';find('SendMessage').MouseButton1Click:Fire();assert(c.sentMetadata=='vanta-reply:reply-one');assert(not allText():find('reply draft',1,true))")
    def test_native_integrated_mode_uses_roblox_window(self):
        self.server();self.runlua('tcs.PlatformIntegratedChat=Enum.RolloutState.Enabled');self.mount()
        self.runlua("assert(find('RobloxChatWindow').Target==channels:FindFirstChild('VantaEN'));assert(not find('Composer').Visible);assert(not find('ComposerInput').TextEditable)")
if __name__=='__main__': unittest.main()


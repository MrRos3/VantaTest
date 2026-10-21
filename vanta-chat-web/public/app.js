const $=id=>document.getElementById(id);
let me=null,csrf="",room="EN",reply=null,known=0,blocks=new Set(),timer=null;
async function api(path,opt={}){
 const res=await fetch("/api/"+path,{credentials:"same-origin",headers:{"Content-Type":"application/json","X-CSRF-Token":csrf},...opt});
 const json=await res.json();if(!res.ok)throw Error(json.error||"Request failed");return json;
}
function toast(value){$("notice").textContent=value;setTimeout(()=>{if($("notice").textContent===value)$("notice").textContent=""},4500)}
function el(tag,cls,value){const x=document.createElement(tag);if(cls)x.className=cls;if(value!==undefined)x.textContent=value;return x}
function showLoggedIn(user,token){me=user;csrf=token;$("auth").hidden=true;$("app").hidden=false;$("status").textContent="● Connected · "+user.name;start()}
function showLoggedOut(){$("auth").hidden=false;$("app").hidden=true;me=null;csrf="";clearInterval(timer);timer=null}
async function account(mode){try{const v=await api("account",{method:"POST",body:JSON.stringify({mode,username:$("username").value,password:$("password").value})});showLoggedIn(v.user,v.csrf)}catch(e){$("auth-error").textContent=e.message}}
$("login").onclick=()=>account("login");$("register").onclick=()=>account("register");
$("logout").onclick=async()=>{try{await api("logout",{method:"POST"})}catch{}showLoggedOut()};
async function load(){if(!me)return;try{const d=await api("messages?room="+room);$("messages").replaceChildren();known=0;for(const m of d.messages){display(m);known=Math.max(known,m.id)}$("messages").scrollTop=$("messages").scrollHeight}catch(e){toast(e.message)}}
async function poll(){if(!me)return;try{const d=await api("messages?room="+room+"&after="+known);for(const m of d.messages){display(m);known=Math.max(known,m.id)}if(d.messages.length)$("messages").scrollTop=$("messages").scrollHeight}catch(e){$("status").textContent="● Reconnecting"}}
function display(m){
 if(blocks.has(m.user_id))return;
 const item=el("div","item"+(me.id===m.user_id?" mine":"")); const avatar=el("div","avatar",m.author[0].toUpperCase());
 const bubble=el("div","bubble"),by=el("div","by",m.author),body=el("div","body",m.content);if(m.room==="AR")body.dir="rtl";
 bubble.append(by);
 if(m.reply_id){const quote=el("div","quote","↩ Reply to #"+m.reply_id);bubble.append(quote)}
 bubble.append(body,el("div","meta",new Date(m.created_at).toLocaleTimeString([],{hour:"2-digit",minute:"2-digit"})));
 const actions=el("div","actions");
 function add(title,action){const b=el("button","",title);b.onclick=action;actions.append(b)}
 add("↩ Reply",()=>{reply=m.id;$("reply-text").textContent="Replying to "+m.author+": "+m.content.slice(0,70);$("reply").hidden=false;$("draft").focus()});
 add("⧉ Copy",()=>navigator.clipboard?.writeText(m.content));
 add("⚑ Report",async()=>{try{await api("report",{method:"POST",body:JSON.stringify({id:m.id,reason:"Inappropriate message"})});toast("Reported for review")}catch(e){toast(e.message)}});
 if(m.user_id!==me.id)add("⊘ Block",async()=>{try{await api("block",{method:"POST",body:JSON.stringify({user_id:m.user_id})});blocks.add(m.user_id);document.querySelectorAll(".item").forEach(x=>{if(x.dataset.uid===String(m.user_id))x.remove()});toast("User blocked")}catch(e){toast(e.message)}});
 bubble.append(actions);item.dataset.uid=String(m.user_id);item.append(avatar,bubble);$("messages").append(item)
}
async function send(){const value=$("draft").value.trim();if(!value)return;try{await api("messages",{method:"POST",body:JSON.stringify({room,content:value,reply_id:reply})});$("draft").value="";reply=null;$("reply").hidden=true;await poll()}catch(e){toast(e.message)}}
$("send").onclick=send;$("draft").onkeydown=e=>{if(e.key==="Enter"&&!e.shiftKey){e.preventDefault();send()}};
$("cancel-reply").onclick=()=>{reply=null;$("reply").hidden=true};
document.querySelectorAll("[data-room]").forEach(btn=>btn.onclick=()=>{room=btn.dataset.room;reply=null;$("reply").hidden=true;document.querySelectorAll("[data-room]").forEach(x=>x.classList.toggle("active",x===btn));$("draft").placeholder=room==="AR"?"اكتب رسالة…":"Message in EN…";$("draft").dir=room==="AR"?"rtl":"ltr";load()});
const emoji="😀 😂 😍 🥹 😭 ❤️ 🖤 🌹 🔥 👍 👀 ✨ 😎 💀 💋 🙏".split(" ");
for(const em of emoji){const b=el("button","",em);b.onclick=()=>{$("draft").value+=em;$("draft").focus()};$("emoji-list").append(b)}
$("emoji-toggle").onclick=()=>{$("emoji-list").hidden=!$("emoji-list").hidden};
function start(){load();clearInterval(timer);timer=setInterval(poll,2500)}
api("me").then(v=>{if(v.user)showLoggedIn(v.user,v.csrf)}).catch(()=>{});

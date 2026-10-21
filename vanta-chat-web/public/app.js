"use strict";
const $ = id => document.getElementById(id);
const iconPath = p => "/icons/" + p + ".svg";
const emojiSet = ["😀","😂","😍","🥹","😭","❤️","🖤","🌹","🔥","👍","👀","✨","😎","💀","💋","🙏"];
let me=null,csrf="",room="EN",reply=null,after=0,online=0,loadSeq=0,polling=false,loading=false,pollTimer=null;
const messageById=new Map(),blockedUsers=new Set();

function icon(name) {
  const i=document.createElement("i");
  i.className="icon";
  i.style.setProperty("--icon",'url("'+iconPath(name)+'")');
  i.setAttribute("aria-hidden","true");
  return i;
}
function mountIcons(){
  document.querySelectorAll("[data-icon]").forEach(x=>{
    x.style.setProperty("--icon",'url("'+iconPath(x.dataset.icon)+'")');
  });
}
function e(tag,className,textValue){
  const node=document.createElement(tag);
  if(className)node.className=className;
  if(textValue!==undefined)node.textContent=String(textValue);
  return node;
}
function toast(message){
  $("notice").textContent=message;
  window.setTimeout(()=>{if($("notice").textContent===message)$("notice").textContent=""},4800);
}
async function api(path,opt={}){
  const response=await fetch("/api/"+path,{
    credentials:"same-origin",
    cache:"no-store",
    headers:{"Content-Type":"application/json","X-CSRF-Token":csrf},
    ...opt,
  });
  let data={};
  try{data=await response.json()}catch{}
  if(!response.ok){
    if(response.status===401 && me) logoutLocal();
    throw Error(data.error||"Request failed ("+response.status+")");
  }
  return data;
}
function logoutLocal(){
  me=null;csrf="";reply=null;
  clearInterval(pollTimer);pollTimer=null;polling=false;
  $("app").hidden=true;$("auth").hidden=false;
  $("status").textContent="Sign in to chat";
}
function loginLocal(user,token){
  me=user;csrf=token;$("auth").hidden=true;$("app").hidden=false;
  $("status").textContent="Connected";
  $("password").value="";
  selectRoom("EN");
  clearInterval(pollTimer);
  pollTimer=setInterval(poll,2600);
}
async function submitAccount(mode){
  $("auth-error").textContent="";
  const username=$("username").value.trim(),password=$("password").value;
  try{
    const data=await api("account",{method:"POST",body:JSON.stringify({
      mode,username,password,invite:$("invite").value.trim(),
      guidelines:$("guidelines").checked,
    })});
    loginLocal(data.user,data.csrf);
  }catch(ex){$("auth-error").textContent=ex.message;}
}
$("register").addEventListener("click",()=>submitAccount("register"));
$("login").addEventListener("click",()=>submitAccount("login"));
$("logout").addEventListener("click",async()=>{
  try{await api("logout",{method:"POST"})}catch{}
  logoutLocal();
});
function statusCount(n){
  online=n;
  $("online").textContent=String(n);
}
function composerReply(message){
  reply=message;
  $("reply-text").textContent=message.author+": "+message.content.slice(0,85);
  $("reply").hidden=false;
  $("draft").focus();
}
function clearReply(){reply=null;$("reply").hidden=true;}
$("cancel-reply").addEventListener("click",clearReply);
function messageTime(seconds){
  return new Date(seconds*1000).toLocaleTimeString([], {hour:"2-digit",minute:"2-digit"});
}
function action(holder,name,iconName,handler){
  const control=e("button","",name);
  control.type="button";
  control.prepend(icon(iconName));
  control.addEventListener("click",handler);
  holder.append(control);
}
function showRow(m){
  messageById.set(m.id,m);
  const mine=me && m.user_id===me.id;
  const row=e("article","item"+(mine?" mine":""));
  row.dataset.uid=String(m.user_id);
  const avatar=e("div","avatar",(m.author||"?").charAt(0).toUpperCase());
  const bubble=e("div","bubble");
  const byline=e("div","byline");
  byline.append(e("span","by",m.author),e("span","time",messageTime(m.created)));
  bubble.append(byline);
  if(m.reply_id){
    const quoted=e("div","quote",m.reply_author
      ? m.reply_author+": "+String(m.reply_content||"").slice(0,95)
      : "↩ Reply to an earlier message");
    bubble.append(quoted);
  }
  const content=e("div","body",m.content);
  content.dir=m.room==="AR"?"rtl":"ltr";
  bubble.append(content);
  if(m.reactions)bubble.append(e("div","reactions",m.reactions));
  const controls=e("div","actions");
  action(controls,"Reply","navigation/corner-up-left",()=>composerReply(m));
  action(controls,"Copy","misc/copy",()=>{
    navigator.clipboard?.writeText(m.content).then(()=>toast("Copied")).catch(()=>toast("Copy not supported here"));
  });
  action(controls,"❤️","social/heart",()=>react(m.id,"❤️"));
  action(controls,"👍","social/heart",()=>react(m.id,"👍"));
  action(controls,"Report","admin/message-square-warning",()=>postAction("report",{id:m.id},"Report submitted"));
  if(!mine){
    action(controls,"Block","security/shield-ban",async()=>{
      if(!confirm("Hide messages from "+m.author+"?"))return;
      try{
        await api("block",{method:"POST",body:JSON.stringify({user_id:m.user_id})});
        blockedUsers.add(m.user_id);
        document.querySelectorAll(".item").forEach(x=>{
          if(x.dataset.uid===String(m.user_id))x.remove();
        });
        toast(m.author+" blocked");
      }catch(ex){toast(ex.message)}
    });
  }else{
    action(controls,"Delete","status/x",async()=>{
      if(!confirm("Delete this message?"))return;
      await postAction("delete",{id:m.id},"Message deleted");
      await load(true);
    });
  }
  bubble.append(controls);
  row.append(avatar,bubble);
  $("messages").append(row);
}
function scrollBottom(){
  $("messages").scrollTop=$("messages").scrollHeight;
}
function showEmpty(){
  if($("messages").childElementCount!==0)return;
  const notice=e("div","empty",room==="AR"
    ?"هلا والله! ابدأ المحادثة العربية 🤍"
    :"Welcome to Vanta Chat. Your room is waiting for its first message. 🌹");
  notice.style.cssText="font-size:13px;color:#d6b9c6;text-align:center;padding:40px 20px";
  $("messages").append(notice);
}
function clearEmpty(){
  $("messages").querySelector(".empty")?.remove();
}
async function load(clear=false){
  if(!me)return;
  const seq=++loadSeq,activeRoom=room;
  if(clear) {$("messages").replaceChildren();messageById.clear();after=0;}
  try{
    const data=await api("messages?room="+encodeURIComponent(activeRoom)+"&after="+(clear?0:after));
    if(seq!==loadSeq||activeRoom!==room||!me)return;
    statusCount(data.online);
    if(data.messages.length)clearEmpty();
    for(const m of data.messages){
      if(messageById.has(m.id))continue;
      if(!blockedUsers.has(m.user_id))showRow(m);
      after=Math.max(after,m.id);
    }
    if(!after)showEmpty();
    if(data.messages.length)scrollBottom();
    $("status").textContent="Connected";
  }catch(ex){
    if(me){$("status").textContent="Reconnecting";toast(ex.message);}
  }
}
async function poll(){
  if(!me||polling)return;
  polling=true;
  try{await load(false)}finally{polling=false}
}
function selectRoom(next){
  if(!me)return;
  room=next; clearReply();after=0;loadSeq++;
  messageById.clear();
  $("messages").replaceChildren();
  document.querySelectorAll("[data-room]").forEach(b=>b.classList.toggle("active",b.dataset.room===next));
  $("draft").placeholder=next==="AR"?"اكتب رسالة...":"Message in EN...";
  $("draft").dir=next==="AR"?"rtl":"ltr";
  load(false);
}
document.querySelectorAll("[data-room]").forEach(b=>b.addEventListener("click",()=>selectRoom(b.dataset.room)));
async function postAction(route,data,success){
  try{
    await api(route,{method:"POST",body:JSON.stringify(data)});
    toast(success);
    return true;
  }catch(ex){toast(ex.message);return false}
}
async function react(id,emoji){
  if(await postAction("react",{id,emoji},"Reaction saved"))await load(true);
}
async function send(){
  if(!me)return;
  const input=$("draft"),content=input.value.trim();
  if(!content)return;
  const b=$("send");b.disabled=true;
  try{
    await api("messages",{method:"POST",body:JSON.stringify({
      room,content,reply_id:reply?.id||null,
    })});
    input.value="";clearReply();$("emoji-list").hidden=true;
    await load(true);
  }catch(ex){toast(ex.message)}
  finally{b.disabled=false}
}
$("send").addEventListener("click",send);
$("draft").addEventListener("keydown",event=>{
  if(event.key==="Enter"&&!event.shiftKey){event.preventDefault();send();}
});
for(const emoji of emojiSet){
  const b=e("button","",emoji);
  b.type="button";
  b.addEventListener("click",()=>{
    $("draft").value+=emoji;$("draft").focus();
  });
  $("emoji-list").append(b);
}
$("emoji-toggle").addEventListener("click",()=>{$("emoji-list").hidden=!$("emoji-list").hidden});
mountIcons();
api("me").then(data=>{
  if(data.user)loginLocal(data.user,data.csrf);
  else logoutLocal();
}).catch(()=>logoutLocal());

const input=JSON.parse(document.getElementById('preview-data').textContent);
const $=id=>document.getElementById(id);
const select=$('action');
for(const name of Object.keys(input.diagnostic.actions)){const o=document.createElement('option');o.value=name;o.textContent=name;select.append(o);}
$('mode').querySelector('[value="codex"]').disabled=!input.capabilities.codexPlayback;
$('identity').textContent=`WebP SHA-256: ${input.assetSha256}\nProfile SHA-256: ${input.profileSha256}\nSource: ${input.source}\nApp: ${input.profile.appVersion??'Diagnostic only'}\nEvidence: ${input.profile.evidence.map(e=>e.level+' / '+e.source).join('; ')||'DIAGNOSTIC — 160 ms per frame'}\nScope: ${input.profile.scope??'Material inspection only; no runtime claim.'}`;
$('sprite').style.backgroundImage=`url("${input.image}")`;
let state=createPlayback(input.diagnostic,'idle');
let anchor=performance.now();
function paint(){
 const f=currentFrame(state),scale=Number($('scale').value);
 $('sprite').style.width=`${192*scale}px`;$('sprite').style.height=`${208*scale}px`;
 $('sprite').style.backgroundSize=`${1536*scale}px ${2288*scale}px`;
 $('sprite').style.backgroundPosition=`${-f.col*192*scale}px ${-f.row*208*scale}px`;
 $('position').textContent=`row ${f.row} · col ${f.col} · ${state.phase} · ${state.playing?'playing':'paused'} · ${state.elapsedMs.toFixed(0)} ms`;
 $('position').dataset.row=f.row;$('position').dataset.col=f.col;$('position').dataset.phase=state.phase;
 $('play').textContent=state.playing?'Pause':'Play';
 $('mode-note').textContent=state.mode==='codex'?'STATIC_VERIFIED sequence · normal motion; loop=false. Not in-app acceptance.':input.capabilities.codexPlayback?'Diagnostic: 160 ms/frame. Codex mode uses the supplied versioned profile.':'Diagnostic: 160 ms/frame. Codex mode unavailable: no complete runtime profile.';
 $('conditions').disabled=state.mode!=='codex'||!input.capabilities.eventSimulation;
 $('event-note').textContent=input.capabilities.eventSimulation?'Enable Codex mode to simulate verified conditions.':'Disabled: complete priority, transition and look-trigger evidence is unavailable.';
 for(const option of select.options)option.disabled=state.mode==='codex'&&!input.profile.actions[option.value];
}
function settle(now=performance.now()){state=reducePlayback(state,{type:'tick',deltaMs:Math.max(0,now-anchor)});anchor=now;}
function dispatch(c){try{settle();state=reducePlayback(state,c);$('error').textContent='';paint();}catch(e){$('error').textContent=e.message;}}
$('play').onclick=()=>dispatch({type:state.playing?'pause':'play'});
$('replay').onclick=()=>dispatch({type:'replay'});
$('previous').onclick=()=>dispatch({type:'step',direction:-1});$('next').onclick=()=>dispatch({type:'step',direction:1});
select.onchange=()=>dispatch({type:'select',action:select.value});
$('mode').onchange=()=>{
 const mode=$('mode').value,profile=mode==='codex'?input.profile:input.diagnostic;
 if(!profile.actions[select.value])select.value='idle';
 try{state=createPlayback(profile,select.value,mode);state=reducePlayback(state,{type:'speed',value:Number($('speed').value)});state=reducePlayback(state,{type:'visibility',hidden:document.hidden});anchor=performance.now();paint();}catch(e){$('error').textContent=e.message;}
};
$('speed').onchange=()=>dispatch({type:'speed',value:Number($('speed').value)});
$('scale').onchange=paint;$('background').onchange=()=>{$('stage').className=$('background').value;};
$('conditions').onchange=()=>dispatch({type:'conditions',activeStates:[...$('conditions').querySelectorAll('input:checked')].map(e=>e.value)});
document.addEventListener('visibilitychange',()=>{settle();state=reducePlayback(state,{type:'visibility',hidden:document.hidden});anchor=performance.now();paint();});
function frame(now){settle(now);paint();requestAnimationFrame(frame);}
paint();requestAnimationFrame(frame);

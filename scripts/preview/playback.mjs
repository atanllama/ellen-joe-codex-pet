const standard=['idle','movingRight','movingLeft','waving','jumping','failed','waiting','running','review'];
const eventNames=['work','waiting','failed','review','idle'];
const complete=a=>a?.frames?.length>0 && a.frames.every(f=>Number.isFinite(f.durationMs)&&f.durationMs>0) && Number.isInteger(a.repeatCount)&&a.repeatCount>0 && ['hold','idle','loop'].includes(a.after);
export function capabilities(p){
 const codexPlayback=p.kind==='codex' && standard.every(s=>complete(p.actions[s]));
 const e=p.events;
 const eventSimulation=codexPlayback && e?.priority?.length===5 && !!e.lookTrigger && standard.every(s=>eventNames.every(event=>e.transitions?.some(r=>r.from===s&&r.event===event)));
 return {codexPlayback,eventSimulation};
}
function check(p,action,mode){
 if(!['once','loop','codex'].includes(mode))throw Error('Unknown mode');
 if(mode==='codex'&&!capabilities(p).codexPlayback)throw Error('Codex playback unavailable: incomplete runtime evidence');
 if(!complete(p.actions[action]))throw Error('Action unavailable: incomplete frame data');
}
export function createPlayback(profile,action,mode='once'){
 check(profile,action,mode);
 return {profile,action,mode,frameIndex:0,elapsedMs:0,phase:'action',playing:true,speed:1,hidden:false,wasPlaying:false,iteration:0};
}
function activeAction(s){return (s.phase==='stopped'?s.stoppedPhase:s.phase)==='idle'?'idle':s.action;}
export function currentFrame(s){return s.profile.actions[activeAction(s)].frames[s.frameIndex];}
function reset(s){return {...s,frameIndex:0,elapsedMs:0,phase:'action',stoppedPhase:null,iteration:0,playing:!s.hidden,wasPlaying:s.hidden};}
function advance(s){
 const a=s.profile.actions[activeAction(s)];
 if(s.frameIndex+1<a.frames.length){s.frameIndex++;return;}
 if(s.mode==='loop'){s.frameIndex=0;return;}
 if(s.mode==='codex'){
  if(++s.iteration<a.repeatCount){s.frameIndex=0;return;}
  if(a.after==='loop'){s.frameIndex=0;s.iteration=0;return;}
  if(a.after==='idle'){s.phase='idle';s.frameIndex=0;s.iteration=0;return;}
 }
 s.playing=false;s.wasPlaying=false;s.stoppedPhase=s.phase;s.phase='stopped';s.elapsedMs=0;
}
export function reducePlayback(previous,c){
 let s={...previous};
 switch(c.type){
  case 'tick':
   if(!Number.isFinite(c.deltaMs)||c.deltaMs<0)throw Error('Invalid delta');
   if(s.playing&&!s.hidden){
    s.elapsedMs+=c.deltaMs*s.speed;
    while(s.playing&&s.elapsedMs>=currentFrame(s).durationMs){s.elapsedMs-=currentFrame(s).durationMs;advance(s);}
   }break;
  case 'play':
   if(s.phase==='stopped')s=reset(s);
   else {s.playing=!s.hidden;s.wasPlaying=s.hidden;}break;
  case 'pause':s.playing=false;s.wasPlaying=false;break;
  case 'replay':s=reset(s);break;
  case 'select':check(s.profile,c.action,s.mode);s=reset({...s,action:c.action});break;
  case 'mode':check(s.profile,s.action,c.value);s=reset({...s,mode:c.value});break;
  case 'step':
   s.playing=false;s.wasPlaying=false;s.elapsedMs=0;
   if(s.phase==='stopped'){s.phase=s.stoppedPhase;s.stoppedPhase=null;s.iteration=0;}
   s.frameIndex=Math.max(0,Math.min(s.profile.actions[activeAction(s)].frames.length-1,s.frameIndex+Math.sign(c.direction)));break;
  case 'speed':if(![.5,1,2].includes(c.value))throw Error('Invalid speed');s.speed=c.value;break;
  case 'visibility':
   if(c.hidden&&!s.hidden){s.wasPlaying=s.playing;s.playing=false;}
   else if(!c.hidden&&s.hidden){s.playing=s.wasPlaying;s.wasPlaying=false;}
   s.hidden=!!c.hidden;break;
  case 'conditions':{
   if(s.mode!=='codex'||!capabilities(s.profile).eventSimulation)throw Error('Event simulation unavailable');
   if(!Array.isArray(c.activeStates)||c.activeStates.some(e=>!eventNames.includes(e)))throw Error('Unknown condition');
   const e=s.profile.events;
   const event=e.priority.find(x=>c.activeStates.includes(x))??'idle';
   const rule=e.transitions.find(r=>r.from===s.action&&r.event===event);
   if(!rule)throw Error('Transition unavailable');
   if(rule.to!==s.action||rule.restart)s=reset({...s,action:rule.to});
   break;
  }
  default:throw Error('Unknown playback command');
 }
 return s;
}

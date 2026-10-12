import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createPlayback,reducePlayback,currentFrame} from '../scripts/preview/playback.mjs';
const diagnostic=JSON.parse(readFileSync(new URL('../qa/playback/v0.1.3/diagnostic-profile.json',import.meta.url)));
const runtime=JSON.parse(readFileSync(new URL('../qa/playback/v0.1.3/codex-profile.json',import.meta.url)));
const cmd=(s,type,extra={})=>reducePlayback(s,{type,...extra});
const tick=(s,deltaMs)=>cmd(s,'tick',{deltaMs});
const fresh=(mode='once')=>createPlayback(diagnostic,'idle',mode);
test('once and loop boundaries exclude neutral',()=>{
 assert.equal(currentFrame(tick(fresh(),160)).col,1);
 assert.equal(currentFrame(tick(fresh(),959)).col,5);
 assert.equal(tick(fresh(),960).playing,false);
 assert.equal(currentFrame(tick(fresh('loop'),960)).col,0);
});
test('pause_preserves_remainder',()=>{
 let s=cmd(tick(fresh(),80),'pause');s=tick(s,5000);s=cmd(s,'play');
 assert.equal(currentFrame(tick(s,80)).col,1);
});
test('visibility_no_catchup',()=>{
 let s=cmd(tick(fresh(),80),'visibility',{hidden:true});assert.equal(s.playing,false);
 s=tick(s,5000);s=cmd(s,'visibility',{hidden:false});assert.equal(currentFrame(tick(s,80)).col,1);
 s=cmd(cmd(fresh(),'pause'),'visibility',{hidden:true});s=cmd(s,'visibility',{hidden:false});assert.equal(s.playing,false);
});
test('select resets; step pauses and clamps',()=>{
 let s=cmd(tick(fresh(),500),'select',{action:'waving'});assert.equal(s.frameIndex,0);assert.equal(s.elapsedMs,0);
 s=cmd(s,'step',{direction:-1});assert.equal(s.playing,false);assert.equal(s.frameIndex,0);
 for(let i=0;i<10;i++)s=cmd(s,'step',{direction:1});assert.equal(s.frameIndex,3);
});
test('speed preserves animation time and pause remainder',()=>{
 let s=cmd(tick(fresh(),80),'speed',{value:2});assert.equal(s.elapsedMs,80);assert.equal(currentFrame(tick(s,40)).col,1);
 assert.equal(currentFrame(tick(cmd(fresh(),'speed',{value:2}),80)).col,1);
});
test('replay and mode reset',()=>{
 let s=cmd(tick(fresh(),960),'replay');assert.equal(s.frameIndex,0);assert.equal(s.playing,true);
 s=cmd(tick(s,240),'mode',{value:'loop'});assert.equal(s.elapsedMs,0);assert.equal(s.frameIndex,0);
});
test('synthetic repeats then idle, once ignores repeats',()=>{
 const p=structuredClone(runtime);for(const a of Object.values(p.actions)){for(const f of a.frames)f.durationMs=160;}
 let s=createPlayback(p,'waving','codex');s=tick(s,1920);assert.equal(s.phase,'idle');assert.equal(currentFrame(s).row,0);
 s=tick(s,960);assert.equal(currentFrame(s).col,0);
 assert.equal(tick(createPlayback(p,'waving'),640).playing,false);
});
test('actual source-backed waving completes at 2100ms into slow idle',()=>{
 let s=createPlayback(runtime,'waving','codex');assert.equal(tick(s,2099).phase,'action');s=tick(s,2100);assert.equal(s.phase,'idle');assert.equal(currentFrame(s).durationMs,1680);
});
test('incomplete core and unsupported events cannot be simulated',()=>{
 let p=structuredClone(runtime);p.actions.failed.frames=null;
 assert.throws(()=>createPlayback(p,'idle','codex'),/unavailable/);
 assert.throws(()=>cmd(createPlayback(runtime,'running','codex'),'conditions',{activeStates:['waiting']}),/unavailable/);
});
test('synthetic condition precedence and restart policy',()=>{
 const p=structuredClone(runtime);p.capabilities={codexPlayback:true,eventSimulation:true};p.events.priority=['waiting','failed','review','work','idle'];p.events.lookTrigger='synthetic';
 p.events.transitions=Object.keys(p.actions).flatMap(from=>p.events.priority.map(event=>({from,event,to:event==='work'?'running':event,restart:event==='work',evidenceIds:['E1']})));
 let s=createPlayback(p,'idle','codex');
 s=cmd(s,'conditions',{activeStates:['work']});assert.equal(s.action,'running');
 for(const event of ['waiting','failed','review']){
  s=cmd(s,'select',{action:'running'});s=cmd(s,'conditions',{activeStates:['work',event]});assert.equal(s.action,event);assert.equal(s.frameIndex,0);
 }
 s=cmd(tick(s,200),'conditions',{activeStates:['review']});assert.equal(s.frameIndex,1);
});
test('reducer does not mutate prior state',()=>{let s=fresh();tick(s,1000);assert.equal(s.frameIndex,0);assert.equal(s.elapsedMs,0);});

test('completed once playback resumes from a manually selected frame',()=>{
 let s=cmd(tick(fresh(),960),'step',{direction:-1});
 assert.equal(currentFrame(s).col,4);assert.equal(s.playing,false);
 s=cmd(s,'play');assert.equal(currentFrame(s).col,4);
 s=tick(s,160);assert.equal(currentFrame(s).col,5);assert.equal(s.playing,true);
 assert.equal(tick(s,160).playing,false);
});

test('returned idle honors repeat and hold while preserving its displayed identity',()=>{
 const p=structuredClone(runtime);p.actions.idle.after='hold';p.actions.idle.repeatCount=2;
 let s=tick(createPlayback(p,'waving','codex'),2100);
 s=tick(s,6600);assert.equal(s.playing,true);assert.equal(currentFrame(s).col,0);
 s=tick(s,6600);assert.equal(s.playing,false);assert.equal(currentFrame(s).row,0);assert.equal(currentFrame(s).col,5);
 s=cmd(s,'step',{direction:-1});assert.equal(currentFrame(s).row,0);assert.equal(currentFrame(s).col,4);
 s=cmd(s,'play');assert.equal(currentFrame(s).row,0);assert.equal(currentFrame(s).col,4);
 s=cmd(s,'replay');assert.equal(currentFrame(s).row,3);assert.equal(currentFrame(s).col,0);
});

// Cycle totals independently transcribed from runtime-evidence.md (normal motion).
const sourceCycles=[['idle',0,6600,6],['movingRight',1,1060,8],['movingLeft',2,1060,8],
 ['waving',3,700,4],['jumping',4,840,5],['failed',5,1220,8],
 ['waiting',6,1010,6],['running',7,820,6],['review',8,1030,6]];
for(const [action,row,cycle,frames] of sourceCycles){
 test(`local acceptance: ${action} boundaries, speeds and visibility`,()=>{
  for(const speed of [.5,1,2]){
   const start=mode=>cmd(createPlayback(runtime,action,mode),'speed',{value:speed});
   let s=tick(start('once'),(cycle-1)/speed);
   assert.equal(currentFrame(s).row,row);assert.equal(s.frameIndex,frames-1);assert.equal(s.playing,true);
   s=tick(s,1/speed);assert.equal(s.playing,false);assert.equal(s.frameIndex,frames-1);
   s=tick(start('loop'),3*cycle/speed);assert.equal(s.playing,true);assert.equal(s.frameIndex,0);assert.equal(currentFrame(s).row,row);
   s=tick(start('codex'),3*cycle/speed);assert.equal(s.playing,true);assert.equal(currentFrame(s).row,0);assert.equal(s.frameIndex,0);
   assert.equal(s.phase,action==='idle'?'action':'idle');
   s=tick(start('codex'),40/speed);s=cmd(s,'visibility',{hidden:true});s=tick(s,60000);
   assert.equal(s.elapsedMs,40);assert.equal(s.playing,false);
   s=cmd(s,'visibility',{hidden:false});assert.equal(s.playing,true);assert.equal(s.elapsedMs,40);
   s=cmd(s,'pause');s=tick(s,60000);assert.equal(s.elapsedMs,40);
  }
 });
}

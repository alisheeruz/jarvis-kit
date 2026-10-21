import {Composition} from 'remotion';
import {Reel} from './Reel';
import {project} from './project';
import captions from './captions.json';
import {scenes} from './scenes';

const FPS = 30;
const end = Math.max(captions.length ? captions[captions.length - 1].e : 0, ...scenes.map((s) => s.to));

export const Root = () => (
  <Composition
    id="Reel"
    component={Reel}
    width={1080}
    height={1920}
    fps={FPS}
    durationInFrames={Math.ceil((end + project.tail) * FPS)}
  />
);

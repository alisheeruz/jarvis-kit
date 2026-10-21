import {Composition} from 'remotion';
import {Reel, DURATION} from './edit';

export const Root = () => (
  <Composition id="Reel" component={Reel} width={1080} height={1920} fps={30} durationInFrames={Math.ceil(DURATION * 30)} />
);

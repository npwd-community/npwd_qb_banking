import App from './src/App';
import { AppIcon } from './icon';

const defaultLanguage = 'en';
const localizedAppName = {
  en: 'Banking',
};

interface Settings {
  language: 'en';
}

export const path = '/banking';
export default (settings: Settings) => ({
  id: 'BANKING',
  path,
  nameLocale: localizedAppName[settings?.language ?? defaultLanguage],
  color: '#fff',
  backgroundColor: '#333',
  icon: AppIcon,
  app: App,
});

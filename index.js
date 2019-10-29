module.exports = () => {
	if (process.platform === 'darwin') {
		return require('./lib').sync();
	}

	throw new Error('sorry, macOS only.');
};

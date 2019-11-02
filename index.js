const path = require('path')
const { promisify } = require('util')
const { execFile, execFileSync } = require('child_process')

const promisedExecFile = promisify(execFile)
const bin = path.join(__dirname, './main')

const parseJSON = string => {
	try {
		return JSON.parse(string)
	} catch (error) {
		throw new Error('Error parsing data')
	}
}

const getOutput = stdout => {
	try {
		const callback = parseJSON(stdout)

		if (callback.error) {
			throw new Error(callback.error)
		} else {
			return callback
		}
	} catch (error) {
		throw new Error(error)
	}
}

module.exports = async app => {
	const { stdout } = await promisedExecFile(bin, [app])
	return getOutput(stdout)
}

module.exports.sync = app => {
	const stdout = execFileSync(bin, [app], { encoding: 'utf8' })
	return getOutput(stdout)
}

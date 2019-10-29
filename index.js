const path = require('path')
const { execFileSync } = require('child_process')
const bin = path.join(__dirname, './main')

const parseMac = stdout => {
	try {
		const result = JSON.parse(stdout)
		if (result !== null) {
			result.platform = 'macos'
			return result
		}
	} catch (error) {
		throw new Error('Error parsing window data')
	}
}

module.exports = () => parseMac(execFileSync(bin, { encoding: 'utf8' }))


var cachedomains = {}
var urltext='';

const downloadJSON = (url, done)=> {
	return fetch(url, {
    method: 'GET',
	})
   .then(response => response.json())
   .then(done)	
}
const download = (url, done)=> {
	return fetch(url, {
    method: 'GET',
	})
	.then(response => response.text())
   .then(done)	
}
const downloadDomainFile = (data) => {
	return download('/cache-domains/' + data.domain_files[0], (domains) => {
		data.domains = domains.split('\n')
	})
}
const downloadDomains = (done) => {
	return downloadJSON('/cache-domains/cache_domains.json', (data)=> {
		cachedomains = data.cache_domains;
		const promises = []
		for(const domain of cachedomains){
			promises.push(downloadDomainFile(domain));
		}
		Promise
		  .all(promises) // (4)
		  .then(done);
	})
}
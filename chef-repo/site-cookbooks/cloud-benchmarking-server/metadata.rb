name             'cloud-benchmarking-server'
maintainer       'seal uzh'
maintainer_email 'joel.scheuner.dev@gmail.com'
license          'Apache 2.0'
description      'Installs and configures the cloud-benchmarking server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 'apt'
depends 'vim'
depends 'vagrant' # Customized cookbook. Improved version of a Github fork of the original cookbook.
depends 'cbench-databox'
depends 'cbench-rackbox'
depends 'cbench-nodejs'
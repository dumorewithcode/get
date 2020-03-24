from setuptools import setup

setup(
        name='ReconForever',
    version='1.0',
    py_modules=['recon'],
    install_requires=[
        'click',
        'validators',
        'futures'
    ],
    entry_points='''
        [console_scripts]
        recon=recon:main
    ''',
)
